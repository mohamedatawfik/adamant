#!/bin/bash

DPP_SCRIPT_PATH="/home/user/scripts/data_preprocessing.sh"
chmod +x "$SCRIPT_PATH"

echo "Setting cron job for Machine 2..."
(crontab -l 2>/dev/null; echo "0 * * * * $DPP_SCRIPT_PATH") | crontab -