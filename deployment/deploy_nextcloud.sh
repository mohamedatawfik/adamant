#!/bin/bash

set -e

echo "Cloning the Adamant repository..."
git clone https://github.com/mohamedatawfik/adamant.git
cd adamant

echo "Installing Nextcloud Scripts Dependencies..."
sudo apt update && sudo apt install -y jq inotifywait

echo "Copying Bash scripts to /home/scripts..."
mkdir -p /home/user/scripts
cp bin/data_preprocessing.sh /home/user/scripts/
chmod +x /home/user/scripts/data_preprocessing.sh

echo "Nextcloud Machine setup complete."