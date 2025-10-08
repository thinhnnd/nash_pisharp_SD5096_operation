# CD Pipeline Setup Guide

## Overview

This CD (Continuous Deployment) pipeline is located directly in the operation repository and automatically deploys applications when configurations are updated.

## Location

```
nash_pisharp_SD5096_operation/
├── azure-pipelines-cd.yml     # CD Pipeline file
├── CD-SETUP-GUIDE.md          # This guide
├── argocd/                    # ArgoCD applications
├── environments/              # Environment configurations
└── scripts/                   # Deployment scripts
```

## Pipeline Flow

```
Operation Repo Changes → Azure DevOps Trigger → CD Pipeline → Kubernetes Deployment
```

## Prerequisites

1. **Azure DevOps Project** with access to this repository
2. **Kubernetes Service Connection** to AKS cluster (see `AKS-SERVICE-CONNECTION-SETUP.md`)
3. **kubectl** configured on build agent
4. **ArgoCD** running on Kubernetes cluster

## Setup Instructions

### 1. Setup AKS Service Connection

**IMPORTANT**: You must setup Kubernetes service connection first!

Follow the detailed guide in `AKS-SERVICE-CONNECTION-SETUP.md` to:
- Create Kubernetes service connection in Azure DevOps
- Configure permissions for AKS cluster access
- Verify kubectl connectivity

### 2. Create CD Pipeline in Azure DevOps

### 2. Create CD Pipeline in Azure DevOps

1. Go to Azure DevOps → Pipelines → New Pipeline
2. Select **GitHub** as source
3. Choose the **operation repository** (`nash_pisharp_SD5096_operation`)
4. Select **Existing Azure Pipelines YAML file**
5. Path: `/azure-pipelines-cd.yml`
6. Name: `CD-Deploy-Pipeline`

### 3. Configure Service Connection

#### Kubernetes Connection
- **Required**: Follow `AKS-SERVICE-CONNECTION-SETUP.md` for detailed setup
- **Name**: Update in pipeline if different from default
- **Type**: Kubernetes
- **Target**: Your AKS cluster
- **Namespace**: Default (pipeline will specify namespaces)

### 4. Configure Agent Pool

Update pipeline variables if using different agent:
```yaml
pool:
  name: 'Default'        # Your agent pool
  demands:
  - agent.name -equals THINHPC  # Your agent name
```

## How It Works

### Triggers

The pipeline triggers automatically when changes are made to:
- `environments/*/values.yaml` - Environment configurations
- `argocd/*.yaml` - ArgoCD application definitions
- Only on `main` branch

### Deployment Steps

1. **Checkout** operation repository
2. **Install ArgoCD CLI** (if needed)
3. **Apply ArgoCD Applications** using kubectl
4. **Wait for Pods** to be ready (300s timeout)
5. **Verify Deployment** status
6. **Generate Summary** report

### Environment Logic

- **Demo Environment**: Always deployed when pipeline runs
- **Dev Environment**: Only deployed if commit message contains "dev"

## Usage Examples

### Ops Team Workflow

1. Update image version in environment file:
```yaml
# environments/demo/values.yaml
frontend:
  image:
    tag: "v1.0.123"  # Update this
backend:
  image:
    tag: "v1.0.456"  # Update this
```

2. Commit and push changes:
```bash
git add environments/demo/values.yaml
git commit -m "Update demo environment to v1.0.123/v1.0.456"
git push origin main
```

3. CD pipeline automatically triggers and deploys

### Deploy to Multiple Environments

```bash
# Update dev environment
git add environments/dev/values.yaml
git commit -m "Update dev environment to v1.0.123/v1.0.456"
git push origin main

# Update demo environment  
git add environments/demo/values.yaml
git commit -m "Update demo environment to v1.0.123/v1.0.456"
git push origin main
```

### Manual Alternative

If you prefer manual deployment, use existing scripts:
```powershell
# PowerShell
.\scripts\update-image-tags.ps1 -Environment demo -FrontendTag "v1.0.123" -BackendTag "v1.0.456"

# Bash
./scripts/update-image-tags.sh demo v1.0.123 v1.0.456
```

## Monitoring

### Pipeline Status
- Azure DevOps → Pipelines → CD-Deploy-Pipeline
- View logs for each deployment step

### Kubernetes Status
```bash
# Check pods
kubectl get pods -n nash-pisharp-demo

# Check services
kubectl get svc -n nash-pisharp-demo

# Check ArgoCD applications
kubectl get applications -n argocd
```

### ArgoCD UI
- Access ArgoCD web interface
- Monitor application sync status
- View deployment history

## File Structure After Setup

```
nash_pisharp_SD5096_operation/
├── azure-pipelines-cd.yml           # CD Pipeline (NEW)
├── CD-SETUP-GUIDE.md                # Setup guide (NEW)
├── PIPELINE_SETUP_GUIDE.md          # Updated with CD info
├── argocd/
│   ├── nash-pisharp-demo.yaml       # Demo environment app
│   ├── nash-pisharp-dev.yaml        # Dev environment app
│   └── nash-pisharp-prod.yaml       # Prod environment app
├── environments/
│   ├── demo/values.yaml              # Demo config (triggers CD)
│   ├── dev/values.yaml               # Dev config (triggers CD)
│   └── prod/values.yaml              # Prod config (triggers CD)
└── scripts/
    ├── update-image-tags.ps1         # Manual deployment script
    └── update-image-tags.sh          # Manual deployment script
```

## Benefits

1. **Self-Contained**: CD pipeline lives with deployment configurations
2. **Simplified**: No external pipeline repository needed
3. **Version Control**: Pipeline changes tracked with configurations
4. **Ops-Focused**: Directly managed by operations team
5. **Automated**: No manual intervention required

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Pipeline doesn't trigger | Check trigger paths and branch settings |
| kubectl access denied | Verify Kubernetes service connection |
| Pods not ready | Check image tags and registry access |
| ArgoCD not syncing | Verify ArgoCD application configuration |

### Debug Commands

```bash
# Check Kubernetes events
kubectl get events -n nash-pisharp-demo --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs -n nash-pisharp-demo -l app.kubernetes.io/name=nash-pisharp-app

# Check ArgoCD application status
kubectl get applications -n argocd
kubectl describe application nash-pisharp-demo -n argocd
```

## Next Steps

1. **Test Pipeline**: Make a small change to trigger the pipeline
2. **Monitor Deployment**: Watch the pipeline execution
3. **Verify Applications**: Check that pods are running
4. **Update Documentation**: Add any environment-specific notes