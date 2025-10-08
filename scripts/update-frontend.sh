#!/bin/bash

# Update Frontend Image Script
# Usage: ./update-frontend.sh <environment> <new-frontend-tag>

set -e

ENVIRONMENT=$1
FRONTEND_TAG=$2

if [ $# -ne 2 ]; then
    echo "Usage: $0 <environment> <new-frontend-tag>"
    echo "Example: $0 demo demo-456"
    echo "This will update ONLY frontend image, backend stays unchanged"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|demo|prod)$ ]]; then
    echo "Error: Environment must be one of: dev, demo, prod"
    exit 1
fi

APP_NAME="nash-pisharp-$ENVIRONMENT"

echo "🔄 Updating Frontend Image for $APP_NAME"
echo "New Frontend tag: $FRONTEND_TAG"

# Check if ArgoCD CLI is installed
if ! command -v argocd &> /dev/null; then
    echo "Error: ArgoCD CLI is not installed. Please install it first."
    exit 1
fi

# Get current backend tag (to show what stays unchanged)
CURRENT_BE_TAG=$(argocd app get $APP_NAME -o json | jq -r '.spec.source.helm.parameters[] | select(.name=="backend.image.tag") | .value')

echo "Backend tag (unchanged): $CURRENT_BE_TAG"

# Update only frontend image tag
echo "Updating frontend image tag..."
argocd app set $APP_NAME -p frontend.image.tag=$FRONTEND_TAG

# Show current status
echo ""
echo "✅ Frontend image updated successfully!"
echo "Current image tags:"
echo "  Frontend: $FRONTEND_TAG (NEW)"
echo "  Backend:  $CURRENT_BE_TAG (unchanged)"

# Get application status
echo ""
echo "Application sync status:"
argocd app get $APP_NAME --show-params

echo ""
echo "🎉 Frontend deployment will update automatically via ArgoCD sync!"