#!/bin/bash

# Quick Demo Deployment Script
# Assumes: Infrastructure ready, Images built and pushed to registry

set -e

echo "🚀 Quick Demo Deployment for Nash PiSharp"

# Configuration
FRONTEND_TAG=${1:-"latest"}
BACKEND_TAG=${2:-"latest"}

if [ $# -eq 0 ]; then
    echo "Usage: $0 <frontend-tag> <backend-tag>"
    echo "Example: $0 demo-123 demo-123"
    echo "Using default tags: latest"
fi

echo "Frontend tag: $FRONTEND_TAG"
echo "Backend tag: $BACKEND_TAG"

# 1. Install ArgoCD if not exists
if ! kubectl get namespace argocd &> /dev/null; then
    echo "Installing ArgoCD..."
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    echo "✅ ArgoCD installed"
else
    echo "✅ ArgoCD already exists"
fi

# 2. Deploy demo application
echo "Deploying demo application..."
kubectl apply -f argocd/nash-pisharp-project.yaml
kubectl apply -f argocd/nash-pisharp-demo.yaml
echo "✅ Demo application deployed"

# 3. Update image tags
echo "Updating image tags..."
if command -v argocd &> /dev/null; then
    argocd app set nash-pisharp-demo -p frontend.image.tag=$FRONTEND_TAG
    argocd app set nash-pisharp-demo -p backend.image.tag=$BACKEND_TAG
    echo "✅ Image tags updated via ArgoCD CLI"
else
    echo "⚠️  ArgoCD CLI not found. Update tags manually:"
    echo "   Frontend: $FRONTEND_TAG"
    echo "   Backend: $BACKEND_TAG"
fi

# 4. Wait and verify
echo "Waiting for deployment..."
sleep 30

echo "Demo deployment status:"
kubectl get pods -n nash-pisharp-demo

echo ""
echo "🎉 Demo deployment completed!"
echo ""
echo "Access demo:"
echo "  kubectl port-forward svc/nash-pisharp-frontend-service -n nash-pisharp-demo 3001:3000"
echo "  Then open: http://localhost:3001"
echo ""
echo "ArgoCD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Then open: https://localhost:8080"