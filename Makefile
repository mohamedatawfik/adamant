# Adamant Docker Deployment Makefile

.PHONY: help install machine1 machine2 all status logs clean dev prod

# Default target
help:
	@echo "Adamant Docker Deployment"
	@echo ""
	@echo "Available targets:"
	@echo "  install     - Install dependencies and setup environment"
	@echo "  machine1    - Deploy Machine 1 (Web Server)"
	@echo "  machine2    - Deploy Machine 2 (Nextcloud)"
	@echo "  all         - Deploy both machines"
	@echo "  status      - Show service status"
	@echo "  logs        - Show service logs"
	@echo "  dev         - Start development environment"
	@echo "  prod        - Start production environment"
	@echo "  clean       - Clean up Docker resources"
	@echo "  help        - Show this help message"

# Install dependencies
install:
	@echo "Installing dependencies..."
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "Docker is not installed. Please install Docker first."; \
		exit 1; \
	fi
	@if ! command -v docker-compose >/dev/null 2>&1; then \
		echo "Docker Compose is not installed. Please install Docker Compose first."; \
		exit 1; \
	fi
	@if [ ! -f .env ]; then \
		cp env.example .env; \
		echo "Created .env file from example. Please edit it with your configuration."; \
	fi
	@chmod +x docker/deploy.sh
	@chmod +x docker/scripts/*.sh
	@echo "Dependencies installed successfully!"

# Deploy Machine 1
machine1: install
	@echo "Deploying Machine 1 (Web Server)..."
	@./docker/deploy.sh machine1

# Deploy Machine 2
machine2: install
	@echo "Deploying Machine 2 (Nextcloud)..."
	@./docker/deploy.sh machine2

# Deploy both machines
all: install
	@echo "Deploying both machines..."
	@./docker/deploy.sh all

# Show status
status:
	@./docker/deploy.sh status

# Show logs
logs:
	@./docker/deploy.sh logs

# Development environment
dev: install
	@echo "Starting development environment..."
	@docker-compose -f docker-compose.machine1.yml -f docker-compose.override.yml up -d
	@docker-compose -f docker-compose.machine2.yml -f docker-compose.override.yml up -d

# Production environment
prod: install
	@echo "Starting production environment..."
	@./docker/deploy.sh all

# Clean up
clean:
	@echo "Cleaning up Docker resources..."
	@./docker/deploy.sh cleanup

# Default target
.DEFAULT_GOAL := help