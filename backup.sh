#!/bin/bash
set -euo pipefail

CONFIG_FILE="./backup.config"
LOCK_FILE="/tmp/backup.lock"
LOG_FILE="./backup.log"

# ---------- Logging ----------
log() {
    local level="$1"; shift
    local msg="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $level: $msg" | tee -a "$LOG_FILE"
}

# ---------- Email Simulation ----------
send_email() {
    local subject="$1"
    local body="$2"
    echo -e "To: $EMAIL_ADDRESS\nSubject: $subject\n\n$body\n---\nSent at $(date '+%Y-%m-%d %H:%M:%S')" >> "$EMAIL_SIM"
}

# ---------- Load Config ----------
if [[ ! -f "$CONFIG_FILE" ]]; then
    log "ERROR" "Config file not found: $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

EMAIL_ADDRESS=${EMAIL_ADDRESS:-"backup@local"}
EMAIL_SIM=${EMAIL_SIM:-"./email.txt"}

# ---------- Lock Handling ----------
if [[ -f "$LOCK_FILE" ]]; then
    log "ERROR" "Lock file exists: another backup is running."
    exit 1
fi
trap 'rm -f "$LOCK_FILE"' EXIT
echo $$ > "$LOCK_FILE"
log "INFO" "Acquired lock: $LOCK_FILE"

# ---------- Parse Arguments ----------
DRY_RUN=false
RESTORE_MODE=false
LIST_MODE=false
SOURCE_DIR=""
CUSTOM_TIMESTAMP=""

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [--dry-run|--list|--restore <backup_file> --to <path>|--timestamp <YYYY-MM-DD-HHMM>] <source_folder>"
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --list) LIST_MODE=true; shift ;;
        --restore) RESTORE_MODE=true; BACKUP_FILE="$2"; shift 2 ;;
        --to) RESTORE_PATH="$2"; shift 2 ;;
        --timestamp) CUSTOM_TIMESTAMP="$2"; shift 2 ;;
        *) SOURCE_DIR="$1"; shift ;;
    esac
done

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "Would run: $*"
    else
        eval "$@"
    fi
}

# ---------- List Backups ----------
if [[ "$LIST_MODE" == true ]]; then
    log "INFO" "Listing backups in $BACKUP_DESTINATION"
    ls -lh "$BACKUP_DESTINATION"
    exit 0
fi

# ---------- Restore Mode ----------
if [[ "$RESTORE_MODE" == true ]]; then
    if [[ ! -f "$BACKUP_FILE" ]]; then
        log "ERROR" "Backup file not found: $BACKUP_FILE"
        send_email "Backup Restore Failed" "Backup file not found: $BACKUP_FILE"
        exit 1
    fi
    mkdir -p "$RESTORE_PATH"
    run_cmd "tar -xzf \"$BACKUP_FILE\" -C \"$RESTORE_PATH\""
    log "SUCCESS" "Restored backup to $RESTORE_PATH"
    send_email "Backup Restore Success" "Backup restored successfully to $RESTORE_PATH"
    exit 0
fi

# ---------- Source Checks ----------
if [[ -z "$SOURCE_DIR" ]]; then
    log "ERROR" "No source directory specified."
    exit 1
fi
if [[ ! -d "$SOURCE_DIR" ]]; then
    log "ERROR" "Source folder not found: $SOURCE_DIR"
    send_email "Backup Failed" "Source folder not found: $SOURCE_DIR"
    exit 1
fi
if [[ ! -r "$SOURCE_DIR" ]]; then
    log "ERROR" "Cannot read folder, permission denied: $SOURCE_DIR"
    send_email "Backup Failed" "Cannot read folder, permission denied: $SOURCE_DIR"
    exit 1
fi

mkdir -p "$BACKUP_DESTINATION"

# ---------- Disk Space Check ----------
AVAILABLE=$(df -Pk "$BACKUP_DESTINATION" | awk 'NR==2 {print $4}')
REQUIRED=$(du -sk "$SOURCE_DIR" | awk '{print $1}')
if (( AVAILABLE < REQUIRED )); then
    log "ERROR" "Not enough disk space for backup."
    send_email "Backup Failed" "Not enough disk space."
    exit 1
fi

# ---------- Backup Creation ----------
if [[ -n "$CUSTOM_TIMESTAMP" ]]; then
    TIMESTAMP="$CUSTOM_TIMESTAMP"
else
    TIMESTAMP=$(date '+%Y-%m-%d-%H%M')

fi

BACKUP_FILE="$BACKUP_DESTINATION/backup-$TIMESTAMP.tar.gz"
CHECKSUM_FILE="$BACKUP_FILE.md5"

EXCLUDES=()
IFS=',' read -ra EXC <<< "$EXCLUDE_PATTERNS"
for pattern in "${EXC[@]}"; do
    EXCLUDES+=(--exclude="$pattern")
done

log "INFO" "Starting backup of $SOURCE_DIR"
run_cmd "tar -czf \"$BACKUP_FILE\" ${EXCLUDES[*]} -C \"$(dirname "$SOURCE_DIR")\" \"$(basename "$SOURCE_DIR")\""
run_cmd "md5sum \"$BACKUP_FILE\" > \"$CHECKSUM_FILE\""

if [[ "$DRY_RUN" == false ]]; then
    md5sum -c "$CHECKSUM_FILE" >/dev/null && log "INFO" "Checksum verified successfully"
    tar -tzf "$BACKUP_FILE" >/dev/null && log "INFO" "Backup integrity check passed"
    log "SUCCESS" "Backup created: $BACKUP_FILE"
    send_email "Backup Success" "Backup created successfully: $BACKUP_FILE"
fi

# ---------- Rotation (7 daily / 4 weekly / 3 monthly) ----------
rotate_backups() {
  log "Cleaning old backups..."

  local dir="$BACKUP_DESTINATION"
  local DAILY_KEEP="${DAILY_KEEP:-7}"
  local WEEKLY_KEEP="${WEEKLY_KEEP:-4}"
  local MONTHLY_KEEP="${MONTHLY_KEEP:-3}"

  mapfile -t backups < <(ls -1 "$dir"/backup-*.tar.gz 2>/dev/null | sort)
  [ ${#backups[@]} -eq 0 ] && { log "No backups found."; return; }

  declare -A keep_daily keep_weekly keep_monthly

  for f in "${backups[@]}"; do
    local base date day week month year
    base=$(basename "$f")
    date=$(echo "$base" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
    [ -z "$date" ] && continue

    year=${date:0:4}
    month=${date:5:2}
    day=${date:8:2}
    week=$(date -d "$date" +%Y-%W 2>/dev/null || date -j -f "%Y-%m-%d" "$date" +%Y-%W)

    keep_daily["$date"]="$f"
    keep_weekly["$week"]="$f"
    keep_monthly["$year-$month"]="$f"
  done

  mapfile -t daily_keys < <(printf "%s\n" "${!keep_daily[@]}" | sort -r)
  mapfile -t weekly_keys < <(printf "%s\n" "${!keep_weekly[@]}" | sort -r)
  mapfile -t monthly_keys < <(printf "%s\n" "${!keep_monthly[@]}" | sort -r)

  declare -A keep_files

  for ((i=0; i<${#daily_keys[@]} && i<DAILY_KEEP; i++)); do
    keep_files["${keep_daily[${daily_keys[$i]}]}"]=1
  done
  for ((i=0; i<${#weekly_keys[@]} && i<WEEKLY_KEEP; i++)); do
    keep_files["${keep_weekly[${weekly_keys[$i]}]}"]=1
  done
  for ((i=0; i<${#monthly_keys[@]} && i<MONTHLY_KEEP; i++)); do
    keep_files["${keep_monthly[${monthly_keys[$i]}]}"]=1
  done

  for f in "${backups[@]}"; do
    if [ -z "${keep_files[$f]+exists}" ]; then
      log "INFO" "Deleted old backup: $(basename "$f")"
      rm -f "$f" "$f.md5"
    fi
  done

  log "INFO" "Rotation complete. Kept: ${#keep_files[@]} backups."
}

rotate_backups
log "INFO" "All tasks completed successfully."
exit 0
