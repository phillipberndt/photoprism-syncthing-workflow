#!/bin/bash
# Replace originals on the phone with compressed versions
#
. config.sh

SOURCE_DIR=$COMPRESSED_PICTURES_DIR
TARGET_DIR=$SYNCTHING_PICTURES_DIR
ORIGINALS_DIR=$PHOTOPRISM_ORIGINALS_DIR

find "$SOURCE_DIR" -type f -print0 | while read -d '' -r SRC; do
	TARGET="$TARGET_DIR/${SRC:${#SOURCE_DIR}}"
	TARGET_BASE="${TARGET%_s.*}"
	TARGET_ORIGINAL="${TARGET_BASE}${TARGET:$((${#TARGET_BASE} + 2))}"
	SOURCE_ORIGINAL="$ORIGINALS_DIR/${TARGET_ORIGINAL:${#TARGET_DIR}}"

	[ -e "$TARGET" ] && continue

	DIR="$(dirname "$TARGET")"
	if ! [ -d "$DIR" ]; then
		mkdir -p "$DIR"
		chown syncthing:syncthing "$DIR"
	fi

	cp -p "$SRC" "$TARGET"
	chown syncthing:syncthing "$TARGET"

	echo -n "$SRC -> $TARGET"
	if [ -e "$SOURCE_ORIGINAL" ] && [ -e "$TARGET_ORIGINAL" ]; then
		rm -f "$TARGET_ORIGINAL"
		echo " (removed original)"
	else
		echo
	fi

done
