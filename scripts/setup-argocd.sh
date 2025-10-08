#!/bin/bash

# Script to setup ArgoCD and deploy Nash PiSharp applications
# Usage: ./setup-argocd.sh

set -e

echo "Setting up ArgoCD and Nash PiSharp applications..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Please install it first."
    exit 1
fi

# Create ArgoCD namespace
echo "Creating ArgoCD namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get ArgoCD admin password
echo "Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password: $ARGOCD_PASSWORD"

# Apply ArgoCD project
echo "Creating ArgoCD project..."
kubectl apply -f ../argocd/nash-pisharp-project.yaml

# Apply ApplicationSet
echo "Creating ApplicationSet..."
kubectl apply -f ../argocd/nash-pisharp-applicationset.yaml

# Show created applications
echo "Created applications:"
kubectl get applications -n argocd

echo ""
echo "✅ ArgoCD setup completed!"
echo ""
echo "Next steps:"
echo "1. Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "2. Login with username: admin, password: $ARGOCD_PASSWORD"
echo "3. Update the repoURL in ApplicationSet to point to your GitOps repository"
echo "4. Configure your CI/CD to update image tags using update-image-tags script"