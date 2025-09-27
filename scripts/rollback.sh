#!/bin/bash

# Emergency Rollback Script for Glyfs Production
# Usage: ./rollback.sh [image-tag-or-latest]
# Example: ./rollback.sh latest-working

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[ROLLBACK]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Configuration
ECR_REGISTRY=${ECR_REGISTRY:-"662147645785.dkr.ecr.us-west-1.amazonaws.com"}
ECR_REPOSITORY=${ECR_REPOSITORY:-"glyfs"}
AWS_REGION=${AWS_REGION:-"us-west-1"}
CONTAINER_NAME="glyfs-app"
ROLLBACK_TAG=${1:-"rollback"}

log_warning "🚨 EMERGENCY ROLLBACK INITIATED"
log_info "Rolling back to image tag: $ROLLBACK_TAG"

# Check if we're on the server
if [[ ! -f "/home/ec2-user/.env.production" ]]; then
    log_error "This script must be run on the production server!"
    log_info "SSH to server first: ssh -i ~/.ssh/id_rsa ec2-user@52.8.122.166"
    exit 1
fi

# Login to ECR
log_info "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Check if rollback image exists
ROLLBACK_IMAGE="$ECR_REGISTRY/$ECR_REPOSITORY:$ROLLBACK_TAG"
if ! docker manifest inspect $ROLLBACK_IMAGE > /dev/null 2>&1; then
    log_error "Rollback image not found: $ROLLBACK_IMAGE"
    log_info "Available images:"
    aws ecr describe-images --repository-name $ECR_REPOSITORY --query 'imageDetails[*].imageTags[0]' --output table
    exit 1
fi

# Stop current container
log_info "Stopping current container..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Pull rollback image
log_info "Pulling rollback image..."
docker pull $ROLLBACK_IMAGE

# Start rollback container
log_info "Starting rollback container..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p 8080:8080 \
    --env-file /home/ec2-user/.env.production \
    --log-driver json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    $ROLLBACK_IMAGE

# Health check
log_info "Performing health check..."
sleep 5
for i in {1..10}; do
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        log_info "✅ ROLLBACK SUCCESSFUL!"
        log_info "Application is healthy and running"
        docker ps --filter "name=$CONTAINER_NAME"
        exit 0
    fi
    log_warning "Health check attempt $i/10 failed, waiting..."
    sleep 2
done

log_error "❌ ROLLBACK FAILED - Health check failed"
log_info "Check logs: docker logs $CONTAINER_NAME"
exit 1
