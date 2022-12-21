#!/bin/bash
# Remove images deleted from Photoprism from all other places
#
. config.sh

ORIGINALS_DIR=$PHOTOPRISM_ORIGINALS_DIR
COMPRESSED_DIR=$COMPRESSED_PICTURES_DIR
PHONE_DIR=$SYNCTHING_PICTURES_DIR

for D in "$PHONE_DIR" "$COMPRESSED_DIR"; do
	find "$D" -type f -regextype egrep -regex '.*_s\.(jpg|JPG|mp4|MP4)' -print0 | while read -d '' -r SRC; do
		SREPL="${SRC//∕/\/}"
		TARGET="$ORIGINALS_DIR/${SREPL:${#D}}"
		TARGET_BASE="${TARGET%_s.*}"
		TARGET_ORIGINAL="${TARGET_BASE}${TARGET:$((${#TARGET_BASE} + 2))}"

		[ -e "$TARGET_ORIGINAL" ] && continue

		echo "Delete $SRC"
		rm -f "$SRC"
	done

	find "$D" -type d -empty -delete
done
