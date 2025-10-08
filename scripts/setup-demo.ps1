# Nash PiSharp Demo Environment Setup Script (PowerShell)
# Usage: .\setup-demo.ps1

param(
    [string]$AcrName = "acrnashpisharp.azurecr.io",
    [string]$Namespace = "nash-pisharp-demo",
    [switch]$SkipBuild = $false,
    [switch]$SkipPush = $false
)

$ErrorActionPreference = "Stop"

# Configuration
$DemoTag = "demo-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Colors for output
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error-Custom "kubectl is not installed. Please install it first."
        exit 1
    }
    
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error-Custom "docker is not installed. Please install it first."
        exit 1
    }
    
    try {
        kubectl cluster-info | Out-Null
    }
    catch {
        Write-Error-Custom "kubectl is not connected to a cluster. Please configure your kubeconfig."
        exit 1
    }
    
    Write-Info "Prerequisites check passed ✅"
}

# Setup ArgoCD if not exists
function Install-ArgoCD {
    try {
        kubectl get namespace argocd | Out-Null
        Write-Info "ArgoCD namespace already exists"
    }
    catch {
        Write-Info "Creating ArgoCD namespace and installing ArgoCD..."
        kubectl create namespace argocd
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        Write-Info "Waiting for ArgoCD to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
        
        Write-Info "ArgoCD installed successfully ✅"
        
        # Get admin password
        $ArgoCDPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
        Write-Info "ArgoCD admin password: $ArgoCDPassword"
        Write-Info "Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    }
}

# Build Docker images
function Build-Images {
    if ($SkipBuild) {
        Write-Warn "Skipping image build as requested"
        return
    }
    
    Write-Info "Building Docker images for demo..."
    
    # Check if source directories exist
    if (!(Test-Path "nash_pisharp_SD5096_backend")) {
        Write-Error-Custom "Backend source directory not found. Please run this script from the project root."
        exit 1
    }
    
    if (!(Test-Path "nash_pisharp_SD5096_frontend")) {
        Write-Error-Custom "Frontend source directory not found. Please run this script from the project root."
        exit 1
    }
    
    # Build backend
    Write-Info "Building backend image..."
    Set-Location nash_pisharp_SD5096_backend
    docker build -t "$AcrName/nash-pisharp/backend:$DemoTag" .
    Set-Location ..
    
    # Build frontend
    Write-Info "Building frontend image..."
    Set-Location nash_pisharp_SD5096_frontend
    docker build -t "$AcrName/nash-pisharp/frontend:$DemoTag" .
    Set-Location ..
    
    Write-Info "Docker images built successfully ✅"
    Write-Host "  - Backend: $AcrName/nash-pisharp/backend:$DemoTag"
    Write-Host "  - Frontend: $AcrName/nash-pisharp/frontend:$DemoTag"
}

# Push images to registry
function Push-Images {
    if ($SkipPush) {
        Write-Warn "Skipping image push as requested"
        return
    }
    
    Write-Info "Pushing images to registry..."
    
    # Login to ACR (assumes azure CLI is configured)
    if (Get-Command az -ErrorAction SilentlyContinue) {
        az acr login --name acrnashpisharp
    }
    else {
        Write-Warn "Azure CLI not found. Please login to ACR manually: docker login $AcrName"
        Read-Host "Press enter to continue after login"
    }
    
    docker push "$AcrName/nash-pisharp/backend:$DemoTag"
    docker push "$AcrName/nash-pisharp/frontend:$DemoTag"
    
    Write-Info "Images pushed successfully ✅"
}

# Deploy ArgoCD applications
function Deploy-ArgoCDApps {
    Write-Info "Deploying ArgoCD applications..."
    
    Set-Location nash_pisharp_SD5096_operation
    
    # Apply project
    kubectl apply -f argocd/nash-pisharp-project.yaml
    
    # Apply demo application
    kubectl apply -f argocd/nash-pisharp-demo.yaml
    
    Set-Location ..
    
    Write-Info "ArgoCD applications deployed ✅"
}

# Update image tags
function Update-ImageTags {
    Write-Info "Updating image tags in ArgoCD..."
    
    # Check if argocd CLI is available
    if (Get-Command argocd -ErrorAction SilentlyContinue) {
        # Login to ArgoCD
        Write-Info "Please login to ArgoCD CLI manually if needed"
        
        # Update image tags
        argocd app set nash-pisharp-demo -p frontend.image.tag=$DemoTag
        argocd app set nash-pisharp-demo -p backend.image.tag=$DemoTag
        
        Write-Info "Image tags updated via ArgoCD CLI ✅"
    }
    else {
        Write-Warn "ArgoCD CLI not found. Please update image tags manually:"
        Write-Host "  Frontend tag: $DemoTag"
        Write-Host "  Backend tag: $DemoTag"
        Write-Host ""
        Write-Host "Update via ArgoCD UI or install ArgoCD CLI"
    }
}

# Verify deployment
function Test-Deployment {
    Write-Info "Verifying demo deployment..."
    
    # Wait for namespace to be created
    $timeout = 60
    while ($timeout -gt 0) {
        try {
            kubectl get namespace $Namespace | Out-Null
            break
        }
        catch {
            Write-Host "Waiting for namespace $Namespace to be created..."
            Start-Sleep 5
            $timeout -= 5
        }
    }
    
    if ($timeout -le 0) {
        Write-Error-Custom "Namespace $Namespace was not created within timeout"
        exit 1
    }
    
    # Check pods
    Write-Info "Checking pods in $Namespace..."
    kubectl get pods -n $Namespace
    
    # Check services
    Write-Info "Checking services in $Namespace..."
    kubectl get svc -n $Namespace
    
    # Check ingress
    Write-Info "Checking ingress in $Namespace..."
    kubectl get ingress -n $Namespace
    
    Write-Info "Demo deployment verification completed ✅"
}

# Setup ingress (optional)
function Install-Ingress {
    Write-Info "Setting up ingress access..."
    
    # Check if ingress controller exists
    try {
        kubectl get pods -n ingress-nginx | Out-Null
        Write-Info "NGINX Ingress Controller already exists"
    }
    catch {
        Write-Warn "NGINX Ingress Controller not found. Installing..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
        
        Write-Info "Waiting for ingress controller to be ready..."
        kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s
        
        Write-Info "NGINX Ingress Controller installed ✅"
    }
    
    # Get ingress external IP
    try {
        $ExternalIP = kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
        if ([string]::IsNullOrEmpty($ExternalIP)) {
            $ExternalIP = kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
        }
        
        if (![string]::IsNullOrEmpty($ExternalIP)) {
            Write-Info "Ingress external IP/hostname: $ExternalIP"
            Write-Info "Add to your hosts file (C:\Windows\System32\drivers\etc\hosts):"
            Write-Host "  $ExternalIP demo.nash-pisharp.example.com"
        }
        else {
            Write-Warn "External IP not available yet. Use port-forward for testing:"
            Write-Host "  kubectl port-forward svc/nash-pisharp-frontend-service -n $Namespace 3001:3000"
            Write-Host "  Then access: http://localhost:3001"
        }
    }
    catch {
        Write-Warn "Could not get external IP. Use port-forward for testing."
    }
}

# Main execution
function Main {
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "Nash PiSharp Demo Setup" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan
    
    Test-Prerequisites
    Install-ArgoCD
    Build-Images
    Push-Images
    Deploy-ArgoCDApps
    Update-ImageTags
    
    Write-Info "Waiting for ArgoCD to sync..."
    Start-Sleep 30
    
    Test-Deployment
    Install-Ingress
    
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "✅ Demo Environment Setup Complete!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    Write-Host "2. Access Demo App: https://demo.nash-pisharp.example.com (after DNS setup)"
    Write-Host "3. Or use port-forward: kubectl port-forward svc/nash-pisharp-frontend-service -n $Namespace 3001:3000"
    Write-Host ""
    Write-Host "Demo image tags:"
    Write-Host "  - Frontend: $DemoTag"
    Write-Host "  - Backend: $DemoTag"
    Write-Host ""
    Write-Host "Useful commands:"
    Write-Host "  - Check demo pods: kubectl get pods -n $Namespace"
    Write-Host "  - Check demo logs: kubectl logs -f deployment/nash-pisharp-frontend -n $Namespace"
    Write-Host "  - Update image tags: .\scripts\update-image-tags.ps1 -Environment demo -FrontendTag <new-tag> -BackendTag <new-tag>"
}

# Run main function
try {
    Main
}
catch {
    Write-Error-Custom "Setup failed: $($_.Exception.Message)"
    exit 1
}