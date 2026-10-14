#!/bin/bash

# ==========================================================
# Automaatne varundusskript
# ==========================================================

set -uo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SRC_DIR="$BASE_DIR/src"
BACKUP_DIR="$BASE_DIR/backup"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/backup.log"
IGNORE_FILE="$SRC_DIR/.backupignore"

KEEP_BACKUPS=3

DRY_RUN=false
COMPRESSOR="auto"

TMP_DIR=""
ARCHIVE_NAME=""
TMP_ARCHIVE=""

# ----------------------------------------------------------
# Funktsioonid
# ----------------------------------------------------------

log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG_FILE"
}

die() {
    log "VIGA: $*"
    exit 1
}

cleanup() {
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}

trap cleanup EXIT

usage() {
    echo "Kasutamine:"
    echo "  ./backupexec.sh"
    echo "  ./backupexec.sh --dry-run"
    echo "  ./backupexec.sh --compressor=zstd"
    echo "  ./backupexec.sh --compressor=gzip"
    echo "  ./backupexec.sh --compressor=xz"
}

check_commands() {
    local commands=(
        tar
        du
        df
        awk
        sha256sum
        find
        sort
        mktemp
        grep
        head
    )

    local command_name

    for command_name in "${commands[@]}"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            die "Vajalik käsk puudub: $command_name"
        fi
    done
}

choose_compressor() {

    if [ "$COMPRESSOR" = "auto" ]; then

        if command -v zstd >/dev/null 2>&1; then
            COMPRESSOR="zstd"

        elif command -v gzip >/dev/null 2>&1; then
            COMPRESSOR="gzip"

        elif command -v xz >/dev/null 2>&1; then
            COMPRESSOR="xz"

        else
            die "Ühtegi toetatud kompressorit ei leitud."
        fi
    fi

    case "$COMPRESSOR" in

        zstd)
            command -v zstd >/dev/null 2>&1 ||
                die "zstd ei ole paigaldatud."
            ;;

        gzip)
            command -v gzip >/dev/null 2>&1 ||
                die "gzip ei ole paigaldatud."
            ;;

        xz)
            command -v xz >/dev/null 2>&1 ||
                die "xz ei ole paigaldatud."
            ;;

        *)
            die "Tundmatu kompressor: $COMPRESSOR"
            ;;
    esac
}

check_free_space() {

    local source_size
    local free_space

    source_size=$(du -sb "$SRC_DIR" | awk '{print $1}')
    free_space=$(df -B1 "$BACKUP_DIR" | awk 'NR==2 {print $4}')

    log "Lähtekausta suurus: $source_size baiti"
    log "Vaba ruum: $free_space baiti"

    if [ "$free_space" -lt "$source_size" ]; then
        die "Backupiks ei ole piisavalt vaba ruumi."
    fi

    log "Vaba ruumi kontroll: OK"
}

dry_run() {

    log "DRY RUN - arhiivi ei looda."
    echo
    echo "Backup sisaldaks järgmisi faile:"
    echo

    local parent_dir
    local source_name

    parent_dir="$(dirname "$SRC_DIR")"
    source_name="$(basename "$SRC_DIR")"

    if [ -f "$IGNORE_FILE" ]; then

        tar \
            --exclude-from="$IGNORE_FILE" \
            -cf - \
            -C "$parent_dir" \
            "$source_name" |
            tar -tvf -

    else

        tar \
            -cf - \
            -C "$parent_dir" \
            "$source_name" |
            tar -tvf -
    fi

    local pipe_result=("${PIPESTATUS[@]}")

    if [ "${pipe_result[0]}" -ne 0 ] ||
       [ "${pipe_result[1]}" -ne 0 ]; then

        die "Dry-run ebaõnnestus."
    fi

    echo
    log "DRY RUN valmis."
}

create_archive() {

    local timestamp
    local parent_dir
    local source_name

    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')

    parent_dir="$(dirname "$SRC_DIR")"
    source_name="$(basename "$SRC_DIR")"

    case "$COMPRESSOR" in

        zstd)
            ARCHIVE_NAME="src_${timestamp}.tar.zst"
            ;;

        gzip)
            ARCHIVE_NAME="src_${timestamp}.tar.gz"
            ;;

        xz)
            ARCHIVE_NAME="src_${timestamp}.tar.xz"
            ;;
    esac

    TMP_ARCHIVE="$TMP_DIR/$ARCHIVE_NAME"

    log "Loon arhiivi: $ARCHIVE_NAME"
    log "Kompressor: $COMPRESSOR"

    if [ -f "$IGNORE_FILE" ]; then
        log "Kasutan välistuste faili: $IGNORE_FILE"
    fi

    case "$COMPRESSOR" in

        zstd)

            if [ -f "$IGNORE_FILE" ]; then
                tar \
                    --exclude-from="$IGNORE_FILE" \
                    -I 'zstd -19 -T0' \
                    -cf "$TMP_ARCHIVE" \
                    -C "$parent_dir" \
                    "$source_name"
            else
                tar \
                    -I 'zstd -19 -T0' \
                    -cf "$TMP_ARCHIVE" \
                    -C "$parent_dir" \
                    "$source_name"
            fi
            ;;

        gzip)

            if [ -f "$IGNORE_FILE" ]; then
                tar \
                    --exclude-from="$IGNORE_FILE" \
                    -czf "$TMP_ARCHIVE" \
                    -C "$parent_dir" \
                    "$source_name"
            else
                tar \
                    -czf "$TMP_ARCHIVE" \
                    -C "$parent_dir" \
                    "$source_name"
            fi
            ;;

        xz)

            if [ -f "$IGNORE_FILE" ]; then
                tar \
                    --exclude-from="$IGNORE_FILE" \
                    -cJf "$TMP_ARCHIVE" \
                    -C "$parent_dir" \
                    "$source_name"
            else
                tar \
                    -cJf "$TMP_ARCHIVE" \
                    -C "$parent_dir" \
                    "$source_name"
            fi
            ;;
    esac

    if [ $? -ne 0 ]; then
        die "Arhiivi loomine ebaõnnestus."
    fi

    log "Arhiiv loodud."
}

verify_archive() {

    local list_file="$TMP_DIR/archive_contents.txt"

    log "Kontrollin arhiivi..."

    case "$COMPRESSOR" in

        zstd)
            tar -I 'zstd -d' -tf "$TMP_ARCHIVE" > "$list_file"
            ;;

        gzip)
            tar -tzf "$TMP_ARCHIVE" > "$list_file"
            ;;

        xz)
            tar -tJf "$TMP_ARCHIVE" > "$list_file"
            ;;
    esac

    if [ $? -ne 0 ]; then
        die "Arhiivi ei õnnestunud avada."
    fi

    if [ ! -s "$list_file" ]; then
        die "Arhiiv on tühi."
    fi

    if ! grep -q '^src/' "$list_file"; then
        die "Arhiiv ei sisalda src kataloogi."
    fi

    if ! grep -qE '^src/.+/$' "$list_file"; then
        die "Arhiiv ei sisalda alamkatalooge."
    fi

    echo
    echo "Arhiivi esimesed kirjed:"
    head -n 5 "$list_file"
    echo

    log "Arhiivi kontroll: OK"
}

show_archive_size() {

    local size

    size=$(du -h "$TMP_ARCHIVE" | awk '{print $1}')

    log "Arhiivi suurus: $size"
}

create_checksum() {

    log "Arvutan SHA-256 kontrollsumma..."

    (
        cd "$TMP_DIR" || exit 1

        sha256sum "$ARCHIVE_NAME" \
            > "$ARCHIVE_NAME.sha256"
    )

    if [ $? -ne 0 ]; then
        die "SHA-256 kontrollsumma loomine ebaõnnestus."
    fi
}

verify_checksum() {

    log "Kontrollin SHA-256 kontrollsummat..."

    (
        cd "$TMP_DIR" || exit 1

        sha256sum -c "$ARCHIVE_NAME.sha256"
    )

    if [ $? -ne 0 ]; then
        die "SHA-256 kontroll ebaõnnestus."
    fi

    log "SHA-256 kontroll: OK"
}

save_backup() {

    mv "$TMP_ARCHIVE" "$BACKUP_DIR/"
    mv "$TMP_DIR/$ARCHIVE_NAME.sha256" "$BACKUP_DIR/"

    log "Backup salvestatud:"
    log "$BACKUP_DIR/$ARCHIVE_NAME"
}

rotate_backups() {

    log "Kontrollin vanade backupide arvu..."

    while IFS= read -r old_backup; do

        [ -z "$old_backup" ] && continue

        log "Kustutan vana backupi:"
        log "$old_backup"

        rm -f -- "$old_backup"
        rm -f -- "$old_backup.sha256"

    done < <(
        find "$BACKUP_DIR" \
            -maxdepth 1 \
            -type f \
            \( \
                -name 'src_*.tar.zst' \
                -o -name 'src_*.tar.gz' \
                -o -name 'src_*.tar.xz' \
            \) \
            -printf '%T@ %p\n' |
            sort -nr |
            awk 'NR > 3 {
                sub(/^[^ ]+ /, "")
                print
            }'
    )

    log "Alles hoitakse kuni $KEEP_BACKUPS viimast backupi."
}

show_result() {

    echo
    echo "========================================"
    echo "            BACKUP EDUKAS"
    echo "========================================"
    echo
    echo "Lähtekaust:"
    echo "$SRC_DIR"
    echo
    echo "Arhiiv:"
    echo "$BACKUP_DIR/$ARCHIVE_NAME"
    echo
    echo "Kontrollsumma:"
    echo "$BACKUP_DIR/$ARCHIVE_NAME.sha256"
    echo
    echo "Kompressor:"
    echo "$COMPRESSOR"
    echo
    echo "Logifail:"
    echo "$LOG_FILE"
    echo
}

# ----------------------------------------------------------
# Argumentide töötlemine
# ----------------------------------------------------------

for argument in "$@"; do

    case "$argument" in

        --dry-run)
            DRY_RUN=true
            ;;

        --compressor=zstd)
            COMPRESSOR="zstd"
            ;;

        --compressor=gzip)
            COMPRESSOR="gzip"
            ;;

        --compressor=xz)
            COMPRESSOR="xz"
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        *)
            echo "Tundmatu argument: $argument"
            usage
            exit 1
            ;;
    esac

done

# ----------------------------------------------------------
# Põhiprogramm
# ----------------------------------------------------------

mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

[ -d "$SRC_DIR" ] ||
    die "Lähtekausta ei leitud: $SRC_DIR"

log "========================================"
log "BACKUP START"

check_commands
choose_compressor

log "Lähtekaust: $SRC_DIR"
log "Backup kaust: $BACKUP_DIR"
log "Kompressor: $COMPRESSOR"

if [ "$DRY_RUN" = true ]; then
    dry_run
    exit 0
fi

check_free_space

TMP_DIR=$(mktemp -d "$BACKUP_DIR/.backup_tmp.XXXXXX") ||
    die "Ajutise kataloogi loomine ebaõnnestus."

create_archive
verify_archive
show_archive_size

create_checksum
verify_checksum

save_backup
rotate_backups

log "BACKUP END"
log "========================================"

show_result

exit 0
