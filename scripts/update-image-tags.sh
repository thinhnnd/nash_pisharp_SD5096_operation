#!/bin/bash

# Script to update image tags for ArgoCD applications
# Usage: ./update-image-tags.sh <environment> <frontend-tag> <backend-tag>

set -e

ENVIRONMENT=$1
FRONTEND_TAG=$2
BACKEND_TAG=$3

if [ $# -ne 3 ]; then
    echo "Usage: $0 <environment> <frontend-tag> <backend-tag>"
    echo "Example: $0 dev dev-123 dev-123"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|demo|prod)$ ]]; then
    echo "Error: Environment must be one of: dev, demo, prod"
    exit 1
fi

APP_NAME="nash-pisharp-$ENVIRONMENT"

echo "Updating image tags for $APP_NAME..."
echo "Frontend tag: $FRONTEND_TAG"
echo "Backend tag: $BACKEND_TAG"

# Check if ArgoCD CLI is installed
if ! command -v argocd &> /dev/null; then
    echo "Error: ArgoCD CLI is not installed. Please install it first."
    exit 1
fi

# Update frontend image tag
echo "Updating frontend image tag..."
argocd app set $APP_NAME -p frontend.image.tag=$FRONTEND_TAG

# Update backend image tag
echo "Updating backend image tag..."
argocd app set $APP_NAME -p backend.image.tag=$BACKEND_TAG

# Get application status
echo "Current application status:"
argocd app get $APP_NAME

# For production, remind about manual sync
if [ "$ENVIRONMENT" = "prod" ]; then
    echo ""
    echo "⚠️  PRODUCTION DEPLOYMENT ⚠️"
    echo "Auto-sync is disabled for production."
    echo "Please manually sync the application in ArgoCD UI or run:"
    echo "argocd app sync $APP_NAME"
fi

echo "Image tags updated successfully!"