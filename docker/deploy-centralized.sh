#!/bin/bash

# Centralized Deployment Script for Adamant
# Manages both machines from a single local machine

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

# Machine configurations
MACHINE1_HOST=${MACHINE1_HOST:-"machine1.local"}
MACHINE2_HOST=${MACHINE2_HOST:-"machine2.local"}
MACHINE1_USER=${MACHINE1_USER:-"root"}
MACHINE2_USER=${MACHINE2_USER:-"root"}

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Docker is installed locally
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed locally. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is installed locally
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed locally. Please install Docker Compose first."
        exit 1
    fi
    
    # Check SSH access to both machines
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$MACHINE1_USER@$MACHINE1_HOST" exit 2>/dev/null; then
        log_error "Cannot connect to Machine 1 ($MACHINE1_HOST). Please check SSH configuration."
        exit 1
    fi
    
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$MACHINE2_USER@$MACHINE2_HOST" exit 2>/dev/null; then
        log_error "Cannot connect to Machine 2 ($MACHINE2_HOST). Please check SSH configuration."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Setup Docker contexts for remote machines
setup_docker_contexts() {
    log_info "Setting up Docker contexts for remote machines..."
    
    # Create context for Machine 1
    docker context create machine1 --docker "host=ssh://$MACHINE1_USER@$MACHINE1_HOST" 2>/dev/null || true
    docker context use machine1
    
    # Create context for Machine 2
    docker context create machine2 --docker "host=ssh://$MACHINE2_USER@$MACHINE2_HOST" 2>/dev/null || true
    docker context use machine2
    
    log_success "Docker contexts configured"
}

# Deploy to Machine 1
deploy_machine1() {
    log_info "Deploying to Machine 1 ($MACHINE1_HOST)..."
    
    # Switch to Machine 1 context
    docker context use machine1
    
    # Copy files to remote machine
    rsync -avz --delete \
        --exclude=".git" \
        --exclude="node_modules" \
        --exclude="__pycache__" \
        "$PROJECT_ROOT/" "$MACHINE1_USER@$MACHINE1_HOST:/opt/adamant/"
    
    # Deploy on Machine 1
    ssh "$MACHINE1_USER@$MACHINE1_HOST" << EOF
        cd /opt/adamant
        docker-compose -f docker-compose.machine1.yml down --remove-orphans
        docker-compose -f docker-compose.machine1.yml build --no-cache
        docker-compose -f docker-compose.machine1.yml up -d
EOF
    
    log_success "Machine 1 deployment completed"
}

# Deploy to Machine 2
deploy_machine2() {
    log_info "Deploying to Machine 2 ($MACHINE2_HOST)..."
    
    # Switch to Machine 2 context
    docker context use machine2
    
    # Copy files to remote machine
    rsync -avz --delete \
        --exclude=".git" \
        --exclude="node_modules" \
        --exclude="__pycache__" \
        "$PROJECT_ROOT/" "$MACHINE2_USER@$MACHINE2_HOST:/opt/adamant/"
    
    # Deploy on Machine 2
    ssh "$MACHINE2_USER@$MACHINE2_HOST" << EOF
        cd /opt/adamant
        docker-compose -f docker-compose.machine2.yml down --remove-orphans
        docker-compose -f docker-compose.machine2.yml build --no-cache
        docker-compose -f docker-compose.machine2.yml up -d
EOF
    
    log_success "Machine 2 deployment completed"
}

# Deploy to both machines
deploy_all() {
    log_info "Deploying to both machines..."
    deploy_machine1
    deploy_machine2
    log_success "All machines deployed successfully!"
}

# Show status of both machines
show_status() {
    log_info "Service Status:"
    echo ""
    
    echo "Machine 1 ($MACHINE1_HOST):"
    docker context use machine1
    docker-compose -f docker-compose.machine1.yml ps
    echo ""
    
    echo "Machine 2 ($MACHINE2_HOST):"
    docker context use machine2
    docker-compose -f docker-compose.machine2.yml ps
    echo ""
}

# Show logs from both machines
show_logs() {
    local service=${1:-""}
    local machine=${2:-"machine1"}
    
    if [ -z "$service" ]; then
        log_info "Available services:"
        docker context use "$machine"
        docker-compose -f "docker-compose.$machine.yml" config --services
        return
    fi
    
    docker context use "$machine"
    docker-compose -f "docker-compose.$machine.yml" logs -f "$service"
}

# Clean up both machines
cleanup() {
    log_info "Cleaning up both machines..."
    
    # Clean Machine 1
    docker context use machine1
    ssh "$MACHINE1_USER@$MACHINE1_HOST" << EOF
        cd /opt/adamant
        docker-compose -f docker-compose.machine1.yml down --remove-orphans --volumes
        docker image prune -f
EOF
    
    # Clean Machine 2
    docker context use machine2
    ssh "$MACHINE2_USER@$MACHINE2_HOST" << EOF
        cd /opt/adamant
        docker-compose -f docker-compose.machine2.yml down --remove-orphans --volumes
        docker image prune -f
EOF
    
    log_success "Cleanup completed on both machines"
}

# Main script
main() {
    case "${1:-help}" in
        "machine1")
            check_prerequisites
            setup_docker_contexts
            deploy_machine1
            ;;
        "machine2")
            check_prerequisites
            setup_docker_contexts
            deploy_machine2
            ;;
        "all")
            check_prerequisites
            setup_docker_contexts
            deploy_all
            ;;
        "status")
            setup_docker_contexts
            show_status
            ;;
        "logs")
            setup_docker_contexts
            show_logs "$2" "$3"
            ;;
        "cleanup")
            setup_docker_contexts
            cleanup
            ;;
        "help"|*)
            echo "Adamant Centralized Docker Deployment Script"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  machine1    Deploy to Machine 1 only"
            echo "  machine2    Deploy to Machine 2 only"
            echo "  all         Deploy to both machines"
            echo "  status      Show service status on both machines"
            echo "  logs        Show logs for a service"
            echo "  cleanup     Clean up both machines"
            echo "  help        Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  MACHINE1_HOST    Machine 1 hostname/IP (default: machine1.local)"
            echo "  MACHINE2_HOST    Machine 2 hostname/IP (default: machine2.local)"
            echo "  MACHINE1_USER    SSH user for Machine 1 (default: root)"
            echo "  MACHINE2_USER    SSH user for Machine 2 (default: root)"
            echo ""
            echo "Examples:"
            echo "  MACHINE1_HOST=192.168.1.10 MACHINE2_HOST=192.168.1.11 $0 all"
            echo "  $0 logs backend machine1"
            echo "  $0 status"
            ;;
    esac
}

# Run main function
main "$@"


