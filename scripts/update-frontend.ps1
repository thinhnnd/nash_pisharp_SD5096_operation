# Update Frontend Image Script (PowerShell)
# Usage: .\update-frontend.ps1 -Environment <env> -FrontendTag <tag>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "demo", "prod")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$FrontendTag
)

$AppName = "nash-pisharp-$Environment"

Write-Host "🔄 Updating Frontend Image for $AppName" -ForegroundColor Cyan
Write-Host "New Frontend tag: $FrontendTag" -ForegroundColor Yellow

# Check if ArgoCD CLI is installed
if (!(Get-Command argocd -ErrorAction SilentlyContinue)) {
    Write-Error "ArgoCD CLI is not installed. Please install it first."
    exit 1
}

try {
    # Get current backend tag (to show what stays unchanged)
    $CurrentBeTag = (argocd app get $AppName -o json | ConvertFrom-Json).spec.source.helm.parameters | Where-Object { $_.name -eq "backend.image.tag" } | Select-Object -ExpandProperty value
    
    Write-Host "Backend tag (unchanged): $CurrentBeTag" -ForegroundColor Green

    # Update only frontend image tag
    Write-Host "Updating frontend image tag..." -ForegroundColor Blue
    argocd app set $AppName -p frontend.image.tag=$FrontendTag

    # Show current status
    Write-Host ""
    Write-Host "✅ Frontend image updated successfully!" -ForegroundColor Green
    Write-Host "Current image tags:" -ForegroundColor Yellow
    Write-Host "  Frontend: $FrontendTag (NEW)" -ForegroundColor Yellow
    Write-Host "  Backend:  $CurrentBeTag (unchanged)" -ForegroundColor Yellow

    # Get application status
    Write-Host ""
    Write-Host "Application sync status:" -ForegroundColor Blue
    argocd app get $AppName --show-params

    Write-Host ""
    Write-Host "🎉 Frontend deployment will update automatically via ArgoCD sync!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to update frontend image: $($_.Exception.Message)"
    exit 1
}