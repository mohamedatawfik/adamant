#!/bin/bash

# Data Synchronization Script for Adamant
# Syncs data from Nextcloud machine to local machine

set -e

# Configuration
NEXTCLOUD_HOST=${NEXTCLOUD_HOST:-"nextcloud"}
NEXTCLOUD_USER=${NEXTCLOUD_USER:-"root"}
REMOTE_DATA_DIR=${REMOTE_DATA_DIR:-"/data/sorted"}
LOCAL_DATA_DIR=${LOCAL_DATA_DIR:-"/data/sorted"}
LOG_FILE=${LOG_FILE:-"/app/logs/syncscript.log"}

# Create directories if they don't exist
mkdir -p "$LOCAL_DATA_DIR" "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Test SSH connection
test_ssh() {
    log "Testing SSH connection to $NEXTCLOUD_HOST..."
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "$NEXTCLOUD_USER@$NEXTCLOUD_HOST" exit 2>/dev/null; then
        log "SSH connection successful"
        return 0
    else
        log "ERROR: SSH connection failed"
        return 1
    fi
}

# Sync data using rsync
sync_data() {
    log "Starting data synchronization..."
    
    # Create remote directory if it doesn't exist
    ssh "$NEXTCLOUD_USER@$NEXTCLOUD_HOST" "mkdir -p $REMOTE_DATA_DIR"
    
    # Sync data from remote to local
    if rsync -avz --delete \
        --exclude="*.tmp" \
        --exclude="*.log" \
        "$NEXTCLOUD_USER@$NEXTCLOUD_HOST:$REMOTE_DATA_DIR/" \
        "$LOCAL_DATA_DIR/"; then
        log "Data synchronization completed successfully"
        return 0
    else
        log "ERROR: Data synchronization failed"
        return 1
    fi
}

# Main function
main() {
    log "Starting sync script..."
    
    if ! test_ssh; then
        log "ERROR: Cannot connect to Nextcloud machine. Exiting."
        exit 1
    fi
    
    if sync_data; then
        log "Sync completed successfully"
        exit 0
    else
        log "Sync failed"
        exit 1
    fi
}

# Run main function
main "$@"


