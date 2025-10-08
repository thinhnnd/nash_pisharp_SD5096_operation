# Quick Demo Deployment Script (PowerShell)
# Assumes: Infrastructure ready, Images built and pushed to registry

param(
    [string]$FrontendTag = "latest",
    [string]$BackendTag = "latest"
)

Write-Host "🚀 Quick Demo Deployment for Nash PiSharp" -ForegroundColor Cyan

if ($args.Count -eq 0) {
    Write-Host "Usage: .\quick-deploy.ps1 <frontend-tag> <backend-tag>" -ForegroundColor Yellow
    Write-Host "Example: .\quick-deploy.ps1 demo-123 demo-123" -ForegroundColor Yellow
    Write-Host "Using default tags: latest" -ForegroundColor Yellow
}

Write-Host "Frontend tag: $FrontendTag" -ForegroundColor Green
Write-Host "Backend tag: $BackendTag" -ForegroundColor Green

# 1. Install ArgoCD if not exists
try {
    kubectl get namespace argocd | Out-Null
    Write-Host "✅ ArgoCD already exists" -ForegroundColor Green
}
catch {
    Write-Host "Installing ArgoCD..." -ForegroundColor Blue
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    Write-Host "✅ ArgoCD installed" -ForegroundColor Green
}

# 2. Deploy demo application
Write-Host "Deploying demo application..." -ForegroundColor Blue
kubectl apply -f argocd/nash-pisharp-project.yaml
kubectl apply -f argocd/nash-pisharp-demo.yaml
Write-Host "✅ Demo application deployed" -ForegroundColor Green

# 3. Update image tags
Write-Host "Updating image tags..." -ForegroundColor Blue
if (Get-Command argocd -ErrorAction SilentlyContinue) {
    argocd app set nash-pisharp-demo -p frontend.image.tag=$FrontendTag
    argocd app set nash-pisharp-demo -p backend.image.tag=$BackendTag
    Write-Host "✅ Image tags updated via ArgoCD CLI" -ForegroundColor Green
}
else {
    Write-Host "⚠️  ArgoCD CLI not found. Update tags manually:" -ForegroundColor Yellow
    Write-Host "   Frontend: $FrontendTag"
    Write-Host "   Backend: $BackendTag"
}

# 4. Wait and verify
Write-Host "Waiting for deployment..." -ForegroundColor Blue
Start-Sleep 30

Write-Host "Demo deployment status:" -ForegroundColor Blue
kubectl get pods -n nash-pisharp-demo

Write-Host ""
Write-Host "🎉 Demo deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Access demo:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward svc/nash-pisharp-frontend-service -n nash-pisharp-demo 3001:3000"
Write-Host "  Then open: http://localhost:3001"
Write-Host ""
Write-Host "ArgoCD UI:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward svc/argocd-server -n argocd 8080:443"  
Write-Host "  Then open: https://localhost:8080"