.PHONY: all machine1 machine2

all: machine1 machine2

machine1:
	@echo "Deploying Machine 1 (Web Server)..."
	bash deployment/deploy_web_server.sh
	bash deployment/setup_cron_web_server.sh

machine2:
	@echo "Deploying Machine 2 (Nextcloud)..."
	bash deployment/deploy_nextcloud.sh
	bash deployment/setup_cron_nextcloud.sh