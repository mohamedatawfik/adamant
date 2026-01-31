#!/bin/bash

# Adamant Docker Deployment Script
# This script deploys the Adamant system using Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi

    log_success "Docker and Docker Compose are installed"
}

# Check if .env file exists
check_env() {
    if [ ! -f "$ENV_FILE" ]; then
        log_warning ".env file not found. Creating from example..."
        if [ -f "$PROJECT_ROOT/env.example" ]; then
            cp "$PROJECT_ROOT/env.example" "$ENV_FILE"
            log_success "Created .env file from example. Please edit it with your configuration."
        else
            log_error "No env.example file found. Please create a .env file manually."
            exit 1
        fi
    else
        log_success ".env file found"
    fi
}

# Generate SSL certificates if needed
setup_ssl() {
    local domain=${SSL_DOMAIN:-"localhost"}
    local email=${SSL_EMAIL:-"admin@example.com"}
    
    if [ "$domain" != "localhost" ] && [ ! -f "$PROJECT_ROOT/docker/nginx/ssl/fullchain.pem" ]; then
        log_info "Setting up SSL certificates for $domain"
        
        # Create SSL directory
        mkdir -p "$PROJECT_ROOT/docker/nginx/ssl"
        
        # Generate self-signed certificate for development
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$PROJECT_ROOT/docker/nginx/ssl/privkey.pem" \
            -out "$PROJECT_ROOT/docker/nginx/ssl/fullchain.pem" \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"
        
        log_success "SSL certificates generated"
    fi
}

# Deploy Machine 1 (Web Server)
deploy_machine1() {
    log_info "Deploying Machine 1 (Web Server)..."
    
    cd "$PROJECT_ROOT"
    
    # Build and start services
    docker-compose -f docker-compose.machine1.yml down --remove-orphans
    docker-compose -f docker-compose.machine1.yml build --no-cache
    docker-compose -f docker-compose.machine1.yml up -d
    
    # Wait for services to be healthy
    log_info "Waiting for services to be healthy..."
    sleep 30
    
    # Check service health
    if docker-compose -f docker-compose.machine1.yml ps | grep -q "unhealthy"; then
        log_warning "Some services are unhealthy. Check logs with: docker-compose -f docker-compose.machine1.yml logs"
    else
        log_success "Machine 1 deployed successfully!"
    fi
}

# Deploy Machine 2 (Nextcloud)
deploy_machine2() {
    log_info "Deploying Machine 2 (Nextcloud)..."
    
    cd "$PROJECT_ROOT"
    
    # Build and start services
    docker-compose -f docker-compose.machine2.yml down --remove-orphans
    docker-compose -f docker-compose.machine2.yml build --no-cache
    docker-compose -f docker-compose.machine2.yml up -d
    
    # Wait for services to be healthy
    log_info "Waiting for services to be healthy..."
    sleep 60
    
    # Check service health
    if docker-compose -f docker-compose.machine2.yml ps | grep -q "unhealthy"; then
        log_warning "Some services are unhealthy. Check logs with: docker-compose -f docker-compose.machine2.yml logs"
    else
        log_success "Machine 2 deployed successfully!"
    fi
}

# Deploy both machines
deploy_all() {
    log_info "Deploying both machines..."
    deploy_machine1
    deploy_machine2
    log_success "All machines deployed successfully!"
}

# Show status
show_status() {
    log_info "Service Status:"
    echo ""
    
    if [ -f "$PROJECT_ROOT/docker-compose.machine1.yml" ]; then
        echo "Machine 1 (Web Server):"
        docker-compose -f docker-compose.machine1.yml ps
        echo ""
    fi
    
    if [ -f "$PROJECT_ROOT/docker-compose.machine2.yml" ]; then
        echo "Machine 2 (Nextcloud):"
        docker-compose -f docker-compose.machine2.yml ps
        echo ""
    fi
}

# Show logs
show_logs() {
    local service=${1:-""}
    local machine=${2:-"machine1"}
    
    if [ -z "$service" ]; then
        log_info "Available services:"
        docker-compose -f "docker-compose.$machine.yml" config --services
        return
    fi
    
    docker-compose -f "docker-compose.$machine.yml" logs -f "$service"
}

# Clean up
cleanup() {
    log_info "Cleaning up Docker resources..."
    
    cd "$PROJECT_ROOT"
    
    # Stop and remove containers
    docker-compose -f docker-compose.machine1.yml down --remove-orphans --volumes
    docker-compose -f docker-compose.machine2.yml down --remove-orphans --volumes
    
    # Remove unused images
    docker image prune -f
    
    log_success "Cleanup completed"
}

# Main script
main() {
    case "${1:-help}" in
        "machine1")
            check_docker
            check_env
            setup_ssl
            deploy_machine1
            ;;
        "machine2")
            check_docker
            check_env
            setup_ssl
            deploy_machine2
            ;;
        "all")
            check_docker
            check_env
            setup_ssl
            deploy_all
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "$2" "$3"
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|*)
            echo "Adamant Docker Deployment Script"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  machine1    Deploy Machine 1 (Web Server)"
            echo "  machine2    Deploy Machine 2 (Nextcloud)"
            echo "  all         Deploy both machines"
            echo "  status      Show service status"
            echo "  logs        Show logs for a service"
            echo "  cleanup     Clean up Docker resources"
            echo "  help        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 machine1"
            echo "  $0 logs backend machine1"
            echo "  $0 status"
            ;;
    esac
}

# Run main function
main "$@"


