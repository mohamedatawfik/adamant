#!/bin/bash

set -e

echo "Cloning the Adamant repository..."
git clone https://github.com/mohamedatawfik/adamant.git
cd adamant

echo "Installing dependencies for Machine 1..."
sudo apt update && sudo apt install -y python3-venv mariadb-server mariadb-client nginx certbot python3-certbot-nginx git curl jq inotify-tools rsync

echo "Setting up Python backend..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

sudo tee /etc/systemd/system/adamant-backend.service > /dev/null <<EOF
[Unit]
Description=Adamant Flask Backend via Gunicorn
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$(pwd)
Environment="PATH=$(pwd)/venv/bin"
ExecStart=$(pwd)/venv/bin/gunicorn -b 0.0.0.0:5000 api:app

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start backend service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable adamant-backend
sudo systemctl start adamant-backend


echo "Setting up Node frontend..."
cd ../frontend
npm install && npm run build

echo "Copying build to Nginx root..."
sudo cp -r build /var/www/html/adamant

echo "Setting up Nginx..."
sudo cp ../nginx.default.prod.conf /etc/nginx/conf.d/adamant.conf
sudo systemctl restart nginx

echo "Obtaining SSL with Certbot..."
sudo certbot --nginx -d metadata.empi-rf.de


echo "Copying Bash scripts to /home/user/scripts..."
mkdir -p /home/user/scripts
cp ../bin/insert_data2db.sh /home/user/scripts/
chmod +x /home/user/scripts/insert_data2db.sh

echo "Adamant Web Server Machine setup complete."