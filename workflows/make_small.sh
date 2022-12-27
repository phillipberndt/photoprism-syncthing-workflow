#!/bin/bash
#
# Creates small versions of the entire photoprism library to sync to the phone
#
. config.sh

TARGET_DIR=$COMPRESSED_PICTURES_DIR
SOURCE_DIR=$PHOTOPRISM_ORIGINALS_DIR

fix_date()
{
	NAME="${1:?name}"

	TS="$(basename "$NAME" | sed -nre 's/.*(20[123][0-9])([01][0-9])([0-3][0-9])_([012][0-9])([0-6][0-9])([0-6][0-9]).*/\1-\2-\3T\4:\5:\6/p')"
	if [ -z "$TS" ]; then
		TS="$(file "$NAME" | grep -Eo 'datetime=[0-9: ]+' | cut -d= -f2 | awk '{gsub(/:/, "-", $1); print $1 "T" $2}')"
	fi
	if [ -z "$TS" ]; then
		TS="$(exiftool -d %Y-%m-%dT%H:%M:%SZ -CreateDate "$NAME" | awk '{print $4}')"
	fi

	if [ -z "$TS" ]; then
		return
	fi
	touch -d "$TS" "$NAME"
}

find "$SOURCE_DIR" -regextype egrep -regex '.*.(jpg|JPG|mp4|MP4)' -print0 | while read -r -d '' SRC; do
	SRC_REL="${SRC:${#SOURCE_DIR}}"
	SRC_BASE="${SRC_REL%%/*}"
	SRC_REM="${SRC_REL:$((${#SRC_BASE}+1))}"
	TARGET="$TARGET_DIR/$SRC_BASE/${SRC_REM//\//∕}"
	TARGET_BASE="${TARGET%.*}"
	TARGET="${TARGET_BASE}_s${TARGET:${#TARGET_BASE}}"
	DIR="$(dirname "$TARGET")"

	if [ -e "$TARGET" ]; then
		continue
	fi

	[ -d "$DIR" ] || mkdir -p "$DIR"

	echo -n "$SRC -> $TARGET  .."

	if [[ $SRC =~ [jJ][pP][gG]$ ]]; then
		convert "$SRC" -resize "1900x1900>" -quality 70 "$TARGET"
	else
		ffmpeg -i "$SRC" -strict experimental -map_metadata 0 -vf scale=w=1280:h=1280:force_original_aspect_ratio=decrease -crf 30 -loglevel error "$TARGET" </dev/null
	fi
	if ! [ -e "$TARGET" ]; then
		echo -n "  Last effort: Copying manually.. "
		cp "$SRC" "$TARGET"
	fi
	fix_date "$TARGET"

	RATIO="$(($(stat -c %s "$TARGET") * 100 / $(stat -c %s "$SRC")))"
	echo " ok (ratio: $RATIO%)"
done

find "$TARGET_DIR" -depth -type d -print0 | while read -d '' -r DN; do
	touch -d "@$(find "$DN" -printf '%T@\n' | sort -nr | head -n1)" "$DN"
done
