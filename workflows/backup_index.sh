#!/bin/sh
#  Create a backup of the Photoprism database
. config.sh

backup_file="$BACKUP_DIR/$(date +%Y-%m-%d).sql"

cd "$PHOTOPRISM_DOCKER_COMPOSE_DIR" || exit 1
docker-compose exec -T photoprism photoprism backup --index - > "$backup_file"
if [ "$(wc -c "$backup_file" | awk '{print $1}')" -lt 1048576 ]; then
	echo "Backup smaller than 1 MiB? Too suspicious. Giving up."
	rm "$backup_file"
	exit 1
fi
gzip -5 "$backup_file"

find "$BACKUP_DIR" -mtime +20 -delete
