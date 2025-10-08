#!/bin/bash

# Nash PiSharp Demo Environment Setup Script
# Usage: ./setup-demo.sh

set -e

echo "🚀 Setting up Nash PiSharp Demo Environment..."

# Configuration
NAMESPACE="nash-pisharp-demo"
ACR_NAME="acrnashpisharp.azurecr.io"
DEMO_TAG="demo-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        error "docker is not installed. Please install it first."
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        error "kubectl is not connected to a cluster. Please configure your kubeconfig."
        exit 1
    fi
    
    log "Prerequisites check passed ✅"
}

# Setup ArgoCD if not exists
setup_argocd() {
    if kubectl get namespace argocd &> /dev/null; then
        log "ArgoCD namespace already exists"
    else
        log "Creating ArgoCD namespace and installing ArgoCD..."
        kubectl create namespace argocd
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        log "Waiting for ArgoCD to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
        
        log "ArgoCD installed successfully ✅"
        
        # Get admin password
        ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
        log "ArgoCD admin password: ${ARGOCD_PASSWORD}"
        log "Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    fi
}

# Build Docker images
build_images() {
    log "Building Docker images for demo..."
    
    # Check if source directories exist
    if [ ! -d "nash_pisharp_SD5096_backend" ]; then
        error "Backend source directory not found. Please run this script from the project root."
        exit 1
    fi
    
    if [ ! -d "nash_pisharp_SD5096_frontend" ]; then
        error "Frontend source directory not found. Please run this script from the project root."
        exit 1
    fi
    
    # Build backend
    log "Building backend image..."
    cd nash_pisharp_SD5096_backend
    docker build -t ${ACR_NAME}/nash-pisharp/backend:${DEMO_TAG} .
    cd ..
    
    # Build frontend
    log "Building frontend image..."
    cd nash_pisharp_SD5096_frontend
    docker build -t ${ACR_NAME}/nash-pisharp/frontend:${DEMO_TAG} .
    cd ..
    
    log "Docker images built successfully ✅"
    echo "  - Backend: ${ACR_NAME}/nash-pisharp/backend:${DEMO_TAG}"
    echo "  - Frontend: ${ACR_NAME}/nash-pisharp/frontend:${DEMO_TAG}"
}

# Push images to registry
push_images() {
    log "Pushing images to registry..."
    
    # Login to ACR (assumes azure CLI is configured)
    if command -v az &> /dev/null; then
        az acr login --name acrnashpisharp
    else
        warn "Azure CLI not found. Please login to ACR manually: docker login ${ACR_NAME}"
        read -p "Press enter to continue after login..."
    fi
    
    docker push ${ACR_NAME}/nash-pisharp/backend:${DEMO_TAG}
    docker push ${ACR_NAME}/nash-pisharp/frontend:${DEMO_TAG}
    
    log "Images pushed successfully ✅"
}

# Deploy ArgoCD applications
deploy_argocd_apps() {
    log "Deploying ArgoCD applications..."
    
    cd nash_pisharp_SD5096_operation
    
    # Apply project
    kubectl apply -f argocd/nash-pisharp-project.yaml
    
    # Apply demo application
    kubectl apply -f argocd/nash-pisharp-demo.yaml
    
    cd ..
    
    log "ArgoCD applications deployed ✅"
}

# Update image tags
update_image_tags() {
    log "Updating image tags in ArgoCD..."
    
    # Check if argocd CLI is available
    if command -v argocd &> /dev/null; then
        # Login to ArgoCD
        log "Please login to ArgoCD CLI manually if needed"
        
        # Update image tags
        argocd app set nash-pisharp-demo -p frontend.image.tag=${DEMO_TAG}
        argocd app set nash-pisharp-demo -p backend.image.tag=${DEMO_TAG}
        
        log "Image tags updated via ArgoCD CLI ✅"
    else
        warn "ArgoCD CLI not found. Please update image tags manually:"
        echo "  Frontend tag: ${DEMO_TAG}"
        echo "  Backend tag: ${DEMO_TAG}"
        echo ""
        echo "Update via ArgoCD UI or install ArgoCD CLI:"
        echo "  curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
        echo "  sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
    fi
}

# Verify deployment
verify_deployment() {
    log "Verifying demo deployment..."
    
    # Wait for namespace to be created
    timeout=60
    while [ $timeout -gt 0 ]; do
        if kubectl get namespace ${NAMESPACE} &> /dev/null; then
            break
        fi
        echo "Waiting for namespace ${NAMESPACE} to be created..."
        sleep 5
        timeout=$((timeout-5))
    done
    
    if [ $timeout -le 0 ]; then
        error "Namespace ${NAMESPACE} was not created within timeout"
        exit 1
    fi
    
    # Check pods
    log "Checking pods in ${NAMESPACE}..."
    kubectl get pods -n ${NAMESPACE}
    
    # Check services
    log "Checking services in ${NAMESPACE}..."
    kubectl get svc -n ${NAMESPACE}
    
    # Check ingress
    log "Checking ingress in ${NAMESPACE}..."
    kubectl get ingress -n ${NAMESPACE}
    
    log "Demo deployment verification completed ✅"
}

# Setup ingress (optional)
setup_ingress() {
    log "Setting up ingress access..."
    
    # Check if ingress controller exists
    if kubectl get pods -n ingress-nginx &> /dev/null; then
        log "NGINX Ingress Controller already exists"
    else
        warn "NGINX Ingress Controller not found. Installing..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
        
        log "Waiting for ingress controller to be ready..."
        kubectl wait --namespace ingress-nginx \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/component=controller \
            --timeout=300s
        
        log "NGINX Ingress Controller installed ✅"
    fi
    
    # Get ingress external IP
    EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    fi
    
    if [ -n "$EXTERNAL_IP" ]; then
        log "Ingress external IP/hostname: ${EXTERNAL_IP}"
        log "Add to your /etc/hosts file:"
        echo "  ${EXTERNAL_IP} demo.nash-pisharp.example.com"
    else
        warn "External IP not available yet. Use port-forward for testing:"
        echo "  kubectl port-forward svc/nash-pisharp-frontend-service -n ${NAMESPACE} 3001:3000"
        echo "  Then access: http://localhost:3001"
    fi
}

# Main execution
main() {
    echo "=================================="
    echo "Nash PiSharp Demo Setup"
    echo "=================================="
    
    check_prerequisites
    setup_argocd
    build_images
    push_images
    deploy_argocd_apps
    update_image_tags
    
    log "Waiting for ArgoCD to sync..."
    sleep 30
    
    verify_deployment
    setup_ingress
    
    echo ""
    echo "=================================="
    echo -e "${GREEN}✅ Demo Environment Setup Complete!${NC}"
    echo "=================================="
    echo ""
    echo "Next steps:"
    echo "1. Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "2. Access Demo App: https://demo.nash-pisharp.example.com (after DNS setup)"
    echo "3. Or use port-forward: kubectl port-forward svc/nash-pisharp-frontend-service -n ${NAMESPACE} 3001:3000"
    echo ""
    echo "Demo image tags:"
    echo "  - Frontend: ${DEMO_TAG}"
    echo "  - Backend: ${DEMO_TAG}"
    echo ""
    echo "Useful commands:"
    echo "  - Check demo pods: kubectl get pods -n ${NAMESPACE}"
    echo "  - Check demo logs: kubectl logs -f deployment/nash-pisharp-frontend -n ${NAMESPACE}"
    echo "  - Update image tags: ./scripts/update-image-tags.sh demo <new-tag> <new-tag>"
}

# Run main function
main "$@"