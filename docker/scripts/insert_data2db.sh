#!/bin/bash

# Database Insertion Script for Adamant
# Scans sorted data directory and inserts data into MariaDB

set -e

# Configuration
DB_HOST=${DB_HOST:-"database"}
DB_PORT=${DB_PORT:-"3306"}
DB_USER=${DB_USER:-"adamant_user"}
DB_PASSWORD=${DB_PASSWORD:-"adamant_password"}
DB_NAME=${DB_NAME:-"experiment_data"}
DATA_DIR=${DATA_DIR:-"/data/sorted"}
LOG_FILE=${LOG_FILE:-"/app/logs/insert_data2db.log"}

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Test database connection
test_db_connection() {
    log "Testing database connection..."
    
    if python3 -c "
import pymysql
import sys
try:
    conn = pymysql.connect(
        host='$DB_HOST',
        port=$DB_PORT,
        user='$DB_USER',
        password='$DB_PASSWORD',
        database='$DB_NAME'
    )
    conn.close()
    print('Database connection successful')
    sys.exit(0)
except Exception as e:
    print(f'Database connection failed: {e}')
    sys.exit(1)
"; then
        log "Database connection successful"
        return 0
    else
        log "ERROR: Database connection failed"
        return 1
    fi
}

# Create table if it doesn't exist
create_table() {
    local table_name="$1"
    local schema_file="$2"
    
    log "Creating table: $table_name"
    
    python3 -c "
import pymysql
import json
import sys

# Connect to database
conn = pymysql.connect(
    host='$DB_HOST',
    port=$DB_PORT,
    user='$DB_USER',
    password='$DB_PASSWORD',
    database='$DB_NAME'
)

try:
    with conn.cursor() as cursor:
        # Read schema file
        with open('$schema_file', 'r') as f:
            schema = json.load(f)
        
        # Generate CREATE TABLE statement
        columns = []
        for field, field_type in schema.items():
            if field_type == 'string':
                columns.append(f'{field} TEXT')
            elif field_type == 'number':
                columns.append(f'{field} DECIMAL(20,6)')
            elif field_type == 'integer':
                columns.append(f'{field} INT')
            elif field_type == 'boolean':
                columns.append(f'{field} BOOLEAN')
            else:
                columns.append(f'{field} TEXT')
        
        # Add metadata columns
        columns.extend([
            'id INT AUTO_INCREMENT PRIMARY KEY',
            'created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
            'updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
            'documentlocation TEXT'
        ])
        
        create_sql = f'CREATE TABLE IF NOT EXISTS {table_name} ({', '.join(columns)})'
        cursor.execute(create_sql)
        conn.commit()
        print(f'Table {table_name} created successfully')
        
except Exception as e:
    print(f'Error creating table {table_name}: {e}')
    sys.exit(1)
finally:
    conn.close()
"
}

# Insert data into table
insert_data() {
    local table_name="$1"
    local data_file="$2"
    
    log "Inserting data from $data_file into $table_name"
    
    python3 -c "
import pymysql
import json
import sys

# Connect to database
conn = pymysql.connect(
    host='$DB_HOST',
    port=$DB_PORT,
    user='$DB_USER',
    password='$DB_PASSWORD',
    database='$DB_NAME'
)

try:
    with conn.cursor() as cursor:
        # Read data file
        with open('$data_file', 'r') as f:
            data = json.load(f)
        
        # Prepare data for insertion
        columns = list(data.keys())
        values = list(data.values())
        placeholders = ', '.join(['%s'] * len(columns))
        
        # Check if record already exists (based on documentlocation)
        if 'documentlocation' in data:
            check_sql = f'SELECT id FROM {table_name} WHERE documentlocation = %s'
            cursor.execute(check_sql, (data['documentlocation'],))
            if cursor.fetchone():
                print(f'Record already exists: {data[\"documentlocation\"]}')
                return
        
        # Insert data
        insert_sql = f'INSERT INTO {table_name} ({', '.join(columns)}) VALUES ({placeholders})'
        cursor.execute(insert_sql, values)
        conn.commit()
        print(f'Data inserted successfully into {table_name}')
        
except Exception as e:
    print(f'Error inserting data into {table_name}: {e}')
    sys.exit(1)
finally:
    conn.close()
"
}

# Process all data files
process_data() {
    log "Processing data files..."
    
    local processed_count=0
    local error_count=0
    
    # Find all schema directories
    for schema_dir in "$DATA_DIR"/*; do
        if [ -d "$schema_dir" ]; then
            local table_name=$(basename "$schema_dir")
            log "Processing schema: $table_name"
            
            # Find schema definition file
            local schema_file="$schema_dir/schema.json"
            if [ ! -f "$schema_file" ]; then
                # Create a basic schema from the first data file
                local first_file=$(find "$schema_dir" -name "*.json" | head -1)
                if [ -f "$first_file" ]; then
                    jq 'keys | map({key: ., value: "string"}) | from_entries' "$first_file" > "$schema_file"
                fi
            fi
            
            if [ -f "$schema_file" ]; then
                # Create table
                if create_table "$table_name" "$schema_file"; then
                    # Insert all data files
                    for data_file in "$schema_dir"/*.json; do
                        if [ -f "$data_file" ] && [ "$(basename "$data_file")" != "schema.json" ]; then
                            if insert_data "$table_name" "$data_file"; then
                                ((processed_count++))
                            else
                                ((error_count++))
                            fi
                        fi
                    done
                else
                    ((error_count++))
                fi
            else
                log "ERROR: No schema file found for $table_name"
                ((error_count++))
            fi
        fi
    done
    
    log "Processing complete. Processed: $processed_count, Errors: $error_count"
}

# Main function
main() {
    log "Starting database insertion script..."
    
    if ! test_db_connection; then
        log "ERROR: Cannot connect to database. Exiting."
        exit 1
    fi
    
    process_data
    log "Database insertion script completed"
}

# Run main function
main "$@"


