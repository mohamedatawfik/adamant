#!/bin/bash

# Data Preprocessing Script for Adamant
# Monitors raw data directory and processes new files

set -e

# Configuration
RAW_DIR=${RAW_DIR:-"/data/raw"}
SORTED_DIR=${SORTED_DIR:-"/data/sorted"}
PROCESSED_DIR=${PROCESSED_DIR:-"/data/processed"}
LOG_FILE=${LOG_FILE:-"/app/logs/data_preprocessing.log"}

# Create directories if they don't exist
mkdir -p "$RAW_DIR" "$SORTED_DIR" "$PROCESSED_DIR" "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Process a single JSON file
process_file() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    
    log "Processing file: $filename"
    
    # Check if file is valid JSON
    if ! jq empty "$file_path" 2>/dev/null; then
        log "ERROR: Invalid JSON file: $filename"
        return 1
    fi
    
    # Extract SchemaID from JSON
    local schema_id=$(jq -r '.SchemaID // empty' "$file_path" 2>/dev/null)
    
    if [ -z "$schema_id" ] || [ "$schema_id" = "null" ]; then
        log "ERROR: No SchemaID found in file: $filename"
        return 1
    fi
    
    # Create schema directory
    local schema_dir="$SORTED_DIR/$schema_id"
    mkdir -p "$schema_dir"
    
    # Add documentlocation field
    local temp_file=$(mktemp)
    jq --arg location "$file_path" '. + {documentlocation: $location}' "$file_path" > "$temp_file"
    
    # Move processed file to schema directory
    local target_file="$schema_dir/$filename"
    mv "$temp_file" "$target_file"
    
    # Move original file to processed directory
    mv "$file_path" "$PROCESSED_DIR/"
    
    log "Successfully processed $filename -> $schema_id/$filename"
    return 0
}

# Main processing function
main() {
    log "Starting data preprocessing..."
    
    # Process all JSON files in raw directory
    local processed_count=0
    local error_count=0
    
    for file in "$RAW_DIR"/*.json; do
        if [ -f "$file" ]; then
            if process_file "$file"; then
                ((processed_count++))
            else
                ((error_count++))
            fi
        fi
    done
    
    log "Processing complete. Processed: $processed_count, Errors: $error_count"
}

# Run main function
main "$@"


