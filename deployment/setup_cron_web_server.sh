#!/bin/bash

INSERT2DB_SCRIPT_PATH="/home/user/scripts/insert_data2db.sh"
chmod +x "$SCRIPT_PATH"

echo "Setting cron job for Machine 1..."
(crontab -l 2>/dev/null; echo "0 * * * * $INSERT2DB_SCRIPT_PATH") | crontab -


CRAWLER_SCRIPT_PATH="/home/user/scripts/syncscript.sh"
chmod +x "$SCRIPT_PATH"

echo "Setting cron job for Machine 2..."
(crontab -l 2>/dev/null; echo "0 * * * * $CRAWLER_SCRIPT_PATH") | crontab -