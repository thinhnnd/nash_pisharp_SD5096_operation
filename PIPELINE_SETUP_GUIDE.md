# Pipeline Setup Guide - Individual Repository Strategy

## Overview

This guide explains how to set up Azure DevOps pipelines in individual repositories instead of using a centralized pipeline repository.

## Strategy Change

**Before**: Centralized pipeline repository that monitors external GitHub repositories
**After**: Each repository (backend/frontend) contains its own Azure Pipeline configuration

## Benefits

- **Simplified Management**: Pipeline configuration lives with the source code
- **Better Coupling**: Pipeline changes are versioned with code changes
- **Easier Maintenance**: No need to maintain external pipeline repository
- **Self-Contained**: Each repository is independently deployable

## Setup Instructions

### 1. Backend Repository Setup

1. **Pipeline File**: `azure-pipelines.yml` is already created in the backend repository root
2. **Version File**: `version.json` contains version information
3. **Azure DevOps Configuration**:
   - Create new pipeline in Azure DevOps
   - Connect to backend repository
   - Use existing `azure-pipelines.yml` file
   - Configure ACR service connection

### 2. Frontend Repository Setup

1. **Pipeline File**: `azure-pipelines.yml` has been updated in the frontend repository root
2. **Version File**: `version.json` contains version information
3. **Azure DevOps Configuration**:
   - Create new pipeline in Azure DevOps
   - Connect to frontend repository
   - Use existing `azure-pipelines.yml` file
   - Configure ACR service connection

### 3. Required Service Connections

Both pipelines require:
- **ACR Service Connection**: Named `acrServiceConnection` (update variable if different)
- **GitHub Connection**: For repository access (if using GitHub)
- **Local Agent**: Pipeline is configured to use local agent pool named 'Default' with agent 'THINHPC'

### 4. Agent Configuration

The pipelines are configured to use local agents instead of Microsoft-hosted agents:
```yaml
pool:
  name: 'Default'  # Agent pool name
  demands:
  - agent.name -equals THINHPC  # Specific agent name
```

**Note**: Update the agent pool name and agent name to match your environment.

### 5. Version Management

Each repository manages its own version through `version.json`:
```json
{
  "major": 1,
  "minor": 0,
  "description": "Application description"
}
```

### 6. Image Tagging Strategy

**Main branch**:
- `v{major}.{minor}.{buildId}`
- `latest`

**Develop branch**:
- `v{major}.{minor}.{buildId}`
- `dev-v{major}.{minor}.{buildId}`

**Other branches**:
- `v{major}.{minor}.{buildId}` only

## Migration Steps

### From Centralized Pipeline

1. **Backup**: Keep existing centralized pipeline as backup
2. **Create Individual Pipelines**: Set up pipelines in each repository
3. **Test**: Verify builds work correctly
4. **Switch**: Update deployment configurations to use new image tags
5. **Cleanup**: Remove/disable centralized pipeline when confident

### Update ArgoCD Applications

Update ArgoCD application manifests to reflect new tagging strategy if needed.

## Troubleshooting

### Common Issues

1. **Service Connection**: Ensure ACR service connection name matches pipeline variable
2. **Permissions**: Verify service principal has push permissions to ACR
3. **Build Context**: Dockerfile should be in repository root
4. **Node Version**: Pipeline uses Node.js 18.x, adjust if needed

### Monitoring

- Check Azure DevOps pipeline runs
- Verify images are pushed to ACR
- Monitor ArgoCD for deployment updates

## Continuous Deployment (CD) Pipeline

### Overview

The CD pipeline (`azure-pipelines-cd.yml`) is located directly in this operation repository and automatically deploys applications when configurations are updated.

### CD Pipeline Features

- **Location**: Root of operation repository (`azure-pipelines-cd.yml`)
- **Trigger**: Monitors changes in this repository:
  - `environments/*/values.yaml` (environment configurations)
  - `argocd/*.yaml` (ArgoCD application definitions)
- **Deployment**: Uses kubectl to apply ArgoCD applications
- **Environments**: Deploys to Demo (always) and Dev (conditional)
- **Verification**: Checks deployment status and pod health

### Setup CD Pipeline

1. **Create Pipeline in Azure DevOps**:
   - Name: `CD-Deploy-Pipeline`
   - Repository: **This operation repository**
   - YAML file: `azure-pipelines-cd.yml` (in root)

2. **Configure Service Connections**:
   - Kubernetes service connection for AKS cluster
   - No GitHub connection needed (pipeline in same repo)

3. **Required Variables**:
   - Update agent pool and agent name as needed
   - `argoCDServerUrl`: Your ArgoCD server URL (if using ArgoCD CLI)

### Workflow

1. **Ops Team** updates version in this repo (`environments/demo/values.yaml`)
2. **CD Pipeline** automatically triggers (same repository)
3. **Pipeline** applies updated ArgoCD applications
4. **ArgoCD** syncs and deploys new versions to Kubernetes
5. **Verification** checks deployment health

### File Structure

```
nash_pisharp_SD5096_operation/
├── azure-pipelines-cd.yml     # CD Pipeline (NEW)
├── CD-SETUP-GUIDE.md          # Detailed setup guide
├── environments/               # Trigger CD when changed
│   ├── demo/values.yaml
│   ├── dev/values.yaml
│   └── prod/values.yaml
├── argocd/                    # ArgoCD applications
│   ├── nash-pisharp-demo.yaml
│   ├── nash-pisharp-dev.yaml
│   └── nash-pisharp-prod.yaml
└── scripts/                   # Manual deployment scripts
    ├── update-image-tags.ps1
    └── update-image-tags.sh
```

### Manual Deployment Alternative

If CD pipeline is not desired, use the existing PowerShell scripts:
```powershell
# Update image tags manually
.\scripts\update-image-tags.ps1 -Environment demo -FrontendTag "v1.0.123" -BackendTag "v1.0.456"
```

## Benefits of This Approach

1. **Decentralized**: Each team owns their pipeline
2. **Version Control**: Pipeline changes are tracked with code
3. **Simplified Dependencies**: No external pipeline repository needed
4. **Faster Iterations**: Changes to pipeline don't require separate repository
5. **Better Governance**: Pipeline rules applied per repository
6. **Automated Deployment**: CD pipeline eliminates manual deployment steps
7. **Self-Contained**: Operations team manages both configs and deployment pipeline