#!/bin/sh
# Workflow driver script, run as root at midnight
cd "$(dirname "$(readlink -f "$0")")/" || exit 1
. config.sh

mkdir -p logs
find logs -mtime +30 -delete
LOGFILE=logs/$(date --rfc-3339=date)
exec >"$LOGFILE" 2>&1

echo "Invoking physically_move_albums_to_folders"
./physically_move_albums_to_folders.py
echo

echo "Invoking copy_originals"
./copy_originals.sh
echo

echo "Invoking make small"
nice su -c "./make_small.sh" pi
echo

echo "Involing switch with compressed"
./switch_with_compressed.sh
echo

echo "Invoking remove deleted"
./remove_deleted.sh
echo

echo "Backing up index"
./backup_index.sh
echo
