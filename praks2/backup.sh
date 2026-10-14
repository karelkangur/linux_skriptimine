#!/bin/bash

BACKUP_DIR="$HOME/linux_skriptimine/praks2/backup"
SOURCE_DIR="$HOME/linux_skriptimine"

DATE=$(date +%Y-%m-%d_%H-%M-%S)
ARCHIVE="$BACKUP_DIR/skriptid_$DATE.tar.zst"

mkdir -p "$BACKUP_DIR"

echo "Loon arhiivi..."

cd "$SOURCE_DIR" || exit 1

tar --zstd -cf "$ARCHIVE" praks1 lottery funktsioonid

if [ $? -ne 0 ]; then
    echo "VIGA: arhiivi loomine ebaõnnestus."
    exit 1
fi

echo "Arhiiv loodud:"
echo "$ARCHIVE"

echo
echo "Arvutan SHA-256 kontrollsumma..."

sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"

echo
echo "Kontrollin arhiivi terviklust..."

sha256sum -c "$ARCHIVE.sha256"

if [ $? -eq 0 ]; then
    echo
    echo "Kõik korras."
    echo "Arhiiv: $ARCHIVE"
    echo "Kontrollsumma: $ARCHIVE.sha256"
else
    echo
    echo "VIGA: kontrollsumma ei klapi."
    exit 1
fi
