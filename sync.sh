#!/bin/bash
# Simple one-way sync from server to local
# Manual execution only - reads from sync-config.txt
# SAFETY: Only reads from server, never writes to server
#
# IMPORTANT: Run this script from your LOCAL Mac, NOT from the server!
# The script connects TO the server to sync files FROM server TO your local machine.

set -euo pipefail

# Safety check: Make sure we're not running on the server
# (This is a basic check - you may want to customize the hostname pattern)
if [ -f /.dockerenv ] || ([ -n "${SSH_CONNECTION:-}" ] && [ -n "${SERVER:-}" ] && hostname | grep -q "$(echo "$SERVER" | cut -d'@' -f2 | cut -d'.' -f1)"); then
    echo "ERROR: This script must be run from your LOCAL Mac, not from the server!"
    echo ""
    echo "If you're currently SSH'd into the server, exit first:"
    echo "  exit"
    echo ""
    echo "Then run the script from your local terminal:"
    echo "  /path/to/sync.sh"
    exit 1
fi

# Configuration
SERVER="username@server.example.com"
REMOTE_BASE="/path/to/docs"
CONFIG_FILE="$(dirname "$0")/sync-config.txt"
LOCK_FILE="/tmp/sync-server-to-local.lock"
# Log directory: macOS uses Library/Logs, Linux uses .local/logs
if [[ "$OSTYPE" == "darwin"* ]]; then
    LOG_DIR="${HOME}/Library/Logs/sync-server-to-local"
else
    LOG_DIR="${HOME}/.local/logs/sync-server-to-local"
fi
LOG_FILE="${LOG_DIR}/sync-$(date +%Y%m%d-%H%M%S).log"
DRY_RUN="${SYNC_DRY_RUN:-1}"  # Default to dry-run for safety

# SSH connection sharing to avoid multiple password prompts
SSH_CONTROL_PATH="/tmp/ssh-control-%r@%h:%p"
SSH_OPTS="-o ControlMaster=auto -o ControlPath=$SSH_CONTROL_PATH -o ControlPersist=300"

# Create log directory
mkdir -p "$LOG_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Cleanup function
cleanup() {
    # Close SSH control connection if it exists
    ssh -o ControlPath="$SSH_CONTROL_PATH" -O exit "$SERVER" 2>/dev/null || true
    rm -f "$LOCK_FILE"
    exit "${1:-0}"
}

# Trap signals
trap 'log "Interrupted. Cleaning up..."; cleanup 1' INT TERM

# Safety check: Ensure we're only reading from server
log "═══════════════════════════════════════════════════════════"
log "Server Sync - ONE-WAY ONLY (Server → Local)"
log "═══════════════════════════════════════════════════════════"
log ""
log "SAFETY: This script ONLY reads from server, never writes."
log ""

# Check for lock file
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
        log "✗ Sync already running (PID: $PID). Exiting."
        exit 1
    else
        log "Removing stale lock file."
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo $$ > "$LOCK_FILE"

# Check config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    log "✗ ERROR: Config file not found: $CONFIG_FILE"
    log ""
    log "Create the config file with folder mappings:"
    log "  Format: remote_folder|local_destination"
    log "  Example: folder1|/Users/username/local/folder1"
    cleanup 1
fi

# Check if server host is reachable (just ping, no SSH test)
log "Checking server connectivity..."
SERVER_HOST=$(echo "$SERVER" | cut -d'@' -f2 | cut -d':' -f1)
if ! ping -c 1 -W 2 "$SERVER_HOST" >/dev/null 2>&1; then
    log "✗ Cannot reach server host: $SERVER_HOST"
    log "  Make sure you're on VPN"
    cleanup 1
fi
log "✓ Server host is reachable"
log ""
log "Note: SSH connection will be tested during sync (you may be prompted for password)"

# Load folder mappings from config
SYNC_COUNT=0
SYNC_FAILED=0
SYNC_SUCCESS=true

log ""
log "Reading configuration from: $CONFIG_FILE"
log "───────────────────────────────────────────────────────────"

while IFS='|' read -r remote_folder local_dest || [ -n "$remote_folder" ]; do
    # Skip comments and empty lines
    [[ "$remote_folder" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${remote_folder// }" ]] && continue
    
    # Remove leading/trailing whitespace
    remote_folder=$(echo "$remote_folder" | xargs)
    local_dest=$(echo "$local_dest" | xargs)
    
    # Skip if either is empty
    [[ -z "$remote_folder" ]] && continue
    [[ -z "$local_dest" ]] && continue
    
    # Build full remote path
    remote_path=$(echo "$remote_folder" | sed 's|^/||')
    full_remote="$REMOTE_BASE/$remote_path"
    
    # Ensure local destination is absolute path
    if [[ ! "$local_dest" = /* ]]; then
        log "⚠ WARNING: Local path '$local_dest' is not absolute. Skipping."
        continue
    fi
    
    # Create local directory
    mkdir -p "$local_dest" || {
        log "✗ ERROR: Cannot create local directory: $local_dest"
        SYNC_SUCCESS=false
        ((SYNC_FAILED++))
        continue
    }
    
    ((SYNC_COUNT++))
    
    log ""
    log "[$SYNC_COUNT] Syncing:"
    log "  From: $SERVER:$full_remote/"
    log "  To:   $local_dest/"
    
done < "$CONFIG_FILE"

if [ "$SYNC_COUNT" -eq 0 ]; then
    log ""
    log "✗ ERROR: No valid folder mappings found in config file."
    log "  Format: remote_folder|local_destination"
    cleanup 1
fi

log ""
log "───────────────────────────────────────────────────────────"
log "Found $SYNC_COUNT folder(s) to sync"
log "───────────────────────────────────────────────────────────"

# Build rsync options - SAFETY: Only read operations
RSYNC_OPTS="-avz --progress --human-readable"

# Exclude common development files (these won't be deleted locally)
RSYNC_EXCLUDES=(
    "--exclude=.git"
    "--exclude=.env"
    "--exclude=.env.local"
    "--exclude=node_modules"
    "--exclude=.DS_Store"
    "--exclude=*.log"
    "--exclude=.idea"
    "--exclude=.vscode"
    "--exclude=*.swp"
    "--exclude=*.swo"
    "--exclude=.local-dev"
    "--exclude=local-only"
    "--exclude=.local"
)

# Load additional exclusions if file exists
EXCLUDES_FILE="${HOME}/.sync-excludes"
if [ -f "$EXCLUDES_FILE" ]; then
    log "Loading additional exclusions from $EXCLUDES_FILE"
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        line=$(echo "$line" | xargs)
        if [ -n "$line" ]; then
            RSYNC_EXCLUDES+=("--exclude=$line")
        fi
    done < "$EXCLUDES_FILE"
fi

# Use --delete to remove files that don't exist on server
# BUT exclusions protect local-only files
RSYNC_OPTS="$RSYNC_OPTS --delete"

# Add dry-run if requested
if [ "$DRY_RUN" = "1" ]; then
    RSYNC_OPTS="$RSYNC_OPTS --dry-run"
    log ""
    log "═══════════════════════════════════════════════════════════"
    log "⚠ DRY RUN MODE - No files will be changed"
    log "═══════════════════════════════════════════════════════════"
fi

# Perform sync for each folder
log ""
log "═══════════════════════════════════════════════════════════"
log "Starting sync operations..."
log "═══════════════════════════════════════════════════════════"

SYNC_START=$(date +%s)
CURRENT=0

# Re-read config and perform syncs
while IFS='|' read -r remote_folder local_dest || [ -n "$remote_folder" ]; do
    # Skip comments and empty lines
    [[ "$remote_folder" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${remote_folder// }" ]] && continue
    
    remote_folder=$(echo "$remote_folder" | xargs)
    local_dest=$(echo "$local_dest" | xargs)
    
    [[ -z "$remote_folder" ]] && continue
    [[ -z "$local_dest" ]] && continue
    [[ ! "$local_dest" = /* ]] && continue
    
    remote_path=$(echo "$remote_folder" | sed 's|^/||')
    full_remote="$REMOTE_BASE/$remote_path"
    
    ((CURRENT++))
    
    log ""
    log "───────────────────────────────────────────────────────────"
    log "[$CURRENT/$SYNC_COUNT] Syncing: $remote_folder → $local_dest"
    log "───────────────────────────────────────────────────────────"
    
    FOLDER_START=$(date +%s)
    
    # SAFETY CHECK: Ensure remote path doesn't contain dangerous patterns
    if [[ "$full_remote" =~ \.\. ]] || [[ "$full_remote" =~ ^[^/] ]]; then
        log "✗ ERROR: Invalid remote path (security check failed): $full_remote"
        SYNC_SUCCESS=false
        ((SYNC_FAILED++))
        continue
    fi
    
    # Build rsync command with SSH connection sharing - SAFETY: Server path is source (read-only)
    RSYNC_CMD="rsync $RSYNC_OPTS ${RSYNC_EXCLUDES[*]} -e \"ssh $SSH_OPTS\" \"$SERVER:$full_remote/\" \"$local_dest/\""
    
    log "Command: rsync [options] $SERVER:$full_remote/ → $local_dest/"
    log ""
    
    if eval "$RSYNC_CMD 2>&1" | tee -a "$LOG_FILE"; then
        FOLDER_END=$(date +%s)
        FOLDER_DURATION=$((FOLDER_END - FOLDER_START))
        log ""
        log "✓ Successfully synced in ${FOLDER_DURATION}s"
    else
        FOLDER_END=$(date +%s)
        FOLDER_DURATION=$((FOLDER_END - FOLDER_START))
        log ""
        log "✗ Sync failed (duration: ${FOLDER_DURATION}s)"
        SYNC_SUCCESS=false
        ((SYNC_FAILED++))
    fi
    
done < "$CONFIG_FILE"

SYNC_END=$(date +%s)
DURATION=$((SYNC_END - SYNC_START))

log ""
log "═══════════════════════════════════════════════════════════"
if [ "$SYNC_SUCCESS" = "true" ] && [ "$SYNC_FAILED" -eq 0 ]; then
    log "✓ All folders synced successfully!"
    log "  Total: ${SYNC_COUNT} folder(s) in ${DURATION}s"
    log "  Log: $LOG_FILE"
else
    log "⚠ Sync completed with errors"
    log "  Successful: $((SYNC_COUNT - SYNC_FAILED)) folder(s)"
    log "  Failed: ${SYNC_FAILED} folder(s)"
    log "  Duration: ${DURATION}s"
    log "  Log: $LOG_FILE"
fi
log "═══════════════════════════════════════════════════════════"

cleanup $([ "$SYNC_SUCCESS" = "true" ] && [ "$SYNC_FAILED" -eq 0 ] && echo 0 || echo 1)

