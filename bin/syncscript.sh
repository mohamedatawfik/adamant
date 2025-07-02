#!/bin/bash

# Function to sync directories
sync_dirs() {
	rsync -avz --delete adamant:~/data_sorted/ data_sorted
}

# Initial sync
sync_dirs

#done
while true; do
    sync_dirs
    sleep 1
done
