#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

if [[ -z $1 ]]; then
    echo -e 'OpenVPN Server Environment path cannot be empty. \nUsage: ./backup.sh /home/admin/openvpn'
    exit 1
fi
SERVER_ENV=$1

DATE=$(date +"%d%m%y-%H%M")
# Backup directory
BACKUP_DIR=backup/ovpnserver-$(date +"%d%m%y-%H%M")

echo -e "Backup OpenVPN Server Environment from \"$SERVER_ENV\" to \"$BACKUP_DIR\""
mkdir -p $BACKUP_DIR

# Backup files
cp -Rp $SERVER_ENV/config $BACKUP_DIR/config
cp -Rp $SERVER_ENV/db $BACKUP_DIR/db
cp -Rp $SERVER_ENV/pki $BACKUP_DIR/pki
cp -Rp $SERVER_ENV/staticclients $BACKUP_DIR/staticclients
cp -Rp $SERVER_ENV/clients $BACKUP_DIR/clients
cp -Rp $SERVER_ENV/fw-rules.sh $BACKUP_DIR/fw-rules.sh
cp -Rp $SERVER_ENV/docker-compose.yml $BACKUP_DIR/docker-compose.yml

echo "Backup created at $BACKUP_DIR"