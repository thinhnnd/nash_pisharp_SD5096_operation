# Nash PiSharp GitOps Repository

GitOps repository for Nash PiSharp Todo application using Helm charts and ArgoCD.

## Quick Start

**Prerequisites**: Kubernetes cluster + Backend/Frontend images in registry

```bash
# Deploy demo environment
./scripts/quick-deploy.sh <frontend-tag> <backend-tag>

# Access demo
kubectl port-forward svc/nash-pisharp-frontend-service -n nash-pisharp-demo 3001:3000
# Open: http://localhost:3001
```

**Detailed setup**: See [QUICK_START.md](QUICK_START.md)

## Repository Structure

```
nash_pisharp_SD5096_operation/
├── charts/                          # Helm charts
│   └── nash-pisharp-app/           # Main application chart (copied from infrastructure repo)
│       ├── Chart.yaml
│       ├── values.yaml             # Default values
│       ├── values-dev.yaml
│       ├── values-prod.yaml
│       └── templates/              # Kubernetes manifests templates
├── environments/                    # Environment-specific configurations
│   ├── dev/
│   │   └── values.yaml             # Development environment values
│   ├── demo/
│   │   └── values.yaml             # Demo environment values
│   └── prod/
│       └── values.yaml             # Production environment values
├── argocd/                         # ArgoCD applications
│   ├── nash-pisharp-project.yaml  # ArgoCD project
│   ├── nash-pisharp-applicationset.yaml  # ApplicationSet for all environments
│   ├── nash-pisharp-dev.yaml      # Dev application
│   ├── nash-pisharp-demo.yaml      # Demo application
│   └── nash-pisharp-prod.yaml     # Production application
├── infrastructure/                 # Shared infrastructure components
└── README.md                      # This file
```

## Application Stack

- **Frontend**: React.js (port 3000)
- **Backend**: Node.js + Express (port 3000)  
- **Database**: MongoDB

## Environments

| Environment | Namespace | Auto-sync | Replicas | Purpose |
|-------------|-----------|-----------|----------|---------|
| **dev** | nash-pisharp-dev | ✅ | 1 | Development |
| **demo** | nash-pisharp-demo | ✅ | 1 | Customer demos |
| **prod** | nash-pisharp-prod | ❌ | 3 | Production |

## Image Management

Build and push images to your registry:
```bash
# Backend
docker build -t <registry>/nash-pisharp/backend:<tag> ./backend
docker push <registry>/nash-pisharp/backend:<tag>

# Frontend  
docker build -t <registry>/nash-pisharp/frontend:<tag> ./frontend
docker push <registry>/nash-pisharp/frontend:<tag>
```

Update deployment:
```bash
./scripts/update-image-tags.sh <env> <frontend-tag> <backend-tag>
```

## Common Commands

```bash
# Check applications
kubectl get applications -n argocd

# Check demo environment  
kubectl get pods -n nash-pisharp-demo

# View logs
kubectl logs -f deployment/nash-pisharp-backend -n nash-pisharp-demo

# Access demo locally
kubectl port-forward svc/nash-pisharp-frontend-service -n nash-pisharp-demo 3001:3000
```

## Files Overview

- `charts/nash-pisharp-app/` - Helm chart for the application
- `environments/*/values.yaml` - Environment-specific configurations  
- `argocd/` - ArgoCD application definitions
- `scripts/` - Deployment and utility scripts
- `QUICK_START.md` - Step-by-step setup guide