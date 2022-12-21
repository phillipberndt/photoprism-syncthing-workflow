#!/bin/bash
# Copy original images from Syncthing to Photoprism
#
. config.sh

SOURCE_DIR=$SYNCTHING_PICTURES_DIR/$MAIN_CAMERA_FOLDER_NAME
TARGET_DIR=$PHOTOPRISM_ORIGINALS_DIR/$MAIN_CAMERA_FOLDER_NAME

find "$SOURCE_DIR" -type f -mtime +1 -not -name "*_s*" -print0 | while read -d '' -r SRC; do
	BASE="$(basename "$SRC")"
	TARGET="$TARGET_DIR/$BASE"
	[ -e "$TARGET" ] && continue

	echo "$SRC -> $TARGET"
	cp -p "$SRC" "$TARGET"
	chown photoprism:photoprism "$TARGET"
done

cd "$PHOTOPRISM_DOCKER_COMPOSE_DIR" || exit 1
docker-compose exec -T photoprism photoprism index
