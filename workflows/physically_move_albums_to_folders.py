#!/usr/bin/python3
# Maintain a directory structure reflecting albums
import collections
import grp
import os
import pwd
import re

import yaml


ORIGINALS_DIR = os.environ["PHOTOPRISM_ORIGINALS_DIR"]
SIDECAR_DIR = os.environ["PHOTOPRISM_STORAGE_DIR"] + "/sidecar/"
ALBUMS_DIR = os.environ["PHOTOPRISM_STORAGE_DIR"] + "/albums/album/"
SMALL_DIR = os.environ["COMPRESSED_PICTURES_DIR"]
CAMERA_FOLDER_NAME = os.environ["MAIN_CAMERA_FOLDER_NAME"]

photoprism_uid = pwd.getpwnam("photoprism").pw_uid
photoprism_gid = grp.getgrnam("photoprism").gr_gid
pi_uid = pwd.getpwnam("pi").pw_uid
pi_gid = grp.getgrnam("pi").gr_gid
originals_dir_cache = {}
uid_to_file = collections.defaultdict(list)

print("Creating UID to file mapping..")
for root, dirs, files in os.walk(SIDECAR_DIR):
    # Only act on the Camera folder
    if CAMERA_FOLDER_NAME not in root:
        continue

    for file_name in files:
        if not file_name.endswith(".yml"):
            continue
        path = os.path.join(root, file_name)

        original_path_prefix = os.path.join(ORIGINALS_DIR, path[len(SIDECAR_DIR):-3])
        original_dir = os.path.dirname(original_path_prefix)
        original_file_prefix = os.path.basename(original_path_prefix)
        original_dir_file_list = originals_dir_cache.get(original_dir)
        if not original_dir_file_list:
            try:
                original_dir_file_list = os.listdir(original_dir)
            except FileNotFoundError:
                print("Stale sidecar file %s, discarding" % path)
                continue
            originals_dir_cache[original_dir] = original_dir_file_list
        candidates = [x for x in original_dir_file_list if x.startswith(original_file_prefix)]
        if not candidates:
            print("No original found for for %s" % path)
            continue

        with open(path) as yaml_in:
            metadata = yaml.load(yaml_in)

        uid_to_file[metadata["UID"]].extend((os.path.join(original_dir, c) for c in candidates))


print("Sweeping albums for images to rename..")
rename = {}
for album_file_name in os.listdir(ALBUMS_DIR):
    if not file_name.endswith(".yml"):
        continue
    path = os.path.join(ALBUMS_DIR, album_file_name)
    with open(path) as yaml_in:
        metadata = yaml.load(yaml_in)

        name = metadata.get("Title")
        # Only act on albums following the naming scheme
        if not name or not re.match("^(19|20)[0-9]+", name):
            continue
        for image in metadata.get("Photos", []):
            originals = uid_to_file.get(image["UID"], [])
            if not originals:
                continue
            for original_path in originals:
                expected_path = os.path.join(ORIGINALS_DIR, name, os.path.basename(original_path))
                if expected_path != original_path:
                    if original_path in rename:
                        # Do not operate on images that appear in more than one album
                        rename[original_path] = None
                    else:
                        rename[original_path] = expected_path

for original_path, expected_path in rename.items():
    if expected_path is None:
        print("%s is in more than one album. Ignoring!" % original_path)
        continue
    if os.access(expected_path, os.F_OK):
        print("Cannot rename %s: %s already exists" % (original_path, expected_path))
    print("%s -> %s" % (original_path, expected_path))
    dir_name = os.path.dirname(expected_path)
    if not os.path.isdir(dir_name):
        os.makedirs(dir_name)
        os.chown(dir_name, photoprism_uid, photoprism_gid)
    os.renames(original_path, expected_path)

    # Also move the small version to avoid having to recompute it
    # The other scripts should then take care of syncing with the phone
    small_original_path = os.path.join(SMALL_DIR, original_path[len(ORIGINALS_DIR):])
    small_original_path = "_s".join(os.path.splitext(small_original_path))
    small_expected_path = os.path.join(SMALL_DIR, expected_path[len(ORIGINALS_DIR):])
    small_expected_path = "_s".join(os.path.splitext(small_expected_path))
    if os.access(small_original_path, os.F_OK):
        print("%s -> %s" % (small_original_path, small_expected_path))
        dir_name = os.path.dirname(small_expected_path)
        if not os.path.isdir(dir_name):
            os.makedirs(dir_name)
            os.chown(dir_name, pi_uid, pi_gid)
        os.renames(small_original_path, small_expected_path)

# No need to reindex, the next round of copy_originals will take care of that.

# vim:et ts=4 sw=4
