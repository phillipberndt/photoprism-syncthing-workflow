# Directory in which to store backups for Photoprism
export BACKUP_DIR=/var/photoprism/backup

# Directory containing the docker compose yaml file for Photoprism
# Used to invoke Photoprism commands
export PHOTOPRISM_DOCKER_COMPOSE_DIR=/var/photoprism/docker/

# Name of the subfolder of all synchronized photos that stores new
# photos. In Android, you'd synchronize all of DCIM, and set this
# to Camera.
export MAIN_CAMERA_FOLDER_NAME=Camera/

# Local target folder of the synchronization for Syncthing with the
# phone
export SYNCTHING_PICTURES_DIR=/var/syncthing/Photos/

# Originals folder for Photoprism
export PHOTOPRISM_ORIGINALS_DIR=/var/photoprism/app/originals/

# Folder storing compressed versions of each picture. This intentionally
# duplicates files from the Syncthing folder to simplify the design. Do
# not merge them into one!
export COMPRESSED_PICTURES_DIR=/var/photoprism/small/

# The local storage folder of Photoprism, with subfolders for
# sidecar, albums, etc.
export PHOTOPRISM_STORAGE_DIR=/var/photoprism/app/storage/
