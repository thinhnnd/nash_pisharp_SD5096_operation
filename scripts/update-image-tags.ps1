# PowerShell script to update image tags for ArgoCD applications
# Usage: .\update-image-tags.ps1 -Environment <env> -FrontendTag <tag> -BackendTag <tag>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "demo", "prod")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$FrontendTag,
    
    [Parameter(Mandatory=$true)]
    [string]$BackendTag
)

$AppName = "nash-pisharp-$Environment"

Write-Host "Updating image tags for $AppName..." -ForegroundColor Green
Write-Host "Frontend tag: $FrontendTag" -ForegroundColor Yellow
Write-Host "Backend tag: $BackendTag" -ForegroundColor Yellow

# Check if ArgoCD CLI is installed
if (!(Get-Command argocd -ErrorAction SilentlyContinue)) {
    Write-Error "ArgoCD CLI is not installed. Please install it first."
    exit 1
}

try {
    # Update frontend image tag
    Write-Host "Updating frontend image tag..." -ForegroundColor Blue
    argocd app set $AppName -p frontend.image.tag=$FrontendTag
    
    # Update backend image tag
    Write-Host "Updating backend image tag..." -ForegroundColor Blue
    argocd app set $AppName -p backend.image.tag=$BackendTag
    
    # Get application status
    Write-Host "Current application status:" -ForegroundColor Blue
    argocd app get $AppName
    
    # For production, remind about manual sync
    if ($Environment -eq "prod") {
        Write-Host ""
        Write-Warning "PRODUCTION DEPLOYMENT"
        Write-Host "Auto-sync is disabled for production." -ForegroundColor Red
        Write-Host "Please manually sync the application in ArgoCD UI or run:" -ForegroundColor Yellow
        Write-Host "argocd app sync $AppName" -ForegroundColor Yellow
    }
    
    Write-Host "Image tags updated successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to update image tags: $($_.Exception.Message)"
    exit 1
}