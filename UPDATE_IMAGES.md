# Update Frontend Image Guide

## Khi có Frontend Image mới

### Step 1: Build & Push new image
```bash
# Build new frontend image
cd nash_pisharp_SD5096_frontend
docker build -t acrnashpisharp.azurecr.io/nash-pisharp/frontend:demo-456 .

# Push to registry  
docker push acrnashpisharp.azurecr.io/nash-pisharp/frontend:demo-456
```

### Step 2: Update ONLY Image Tag (NOT Chart Version)
```bash
# Option 1: Using script (recommended)
./scripts/update-image-tags.sh demo demo-456 demo-123
#                                    ^new-FE   ^keep-BE

# Option 2: ArgoCD CLI
argocd app set nash-pisharp-demo -p frontend.image.tag=demo-456
# Backend tag remains unchanged: demo-123

# Option 3: ArgoCD UI
# Go to nash-pisharp-demo → APP DETAILS → PARAMETERS
# Change only: frontend.image.tag = demo-456
```

### Step 3: ArgoCD Auto-Sync
- ArgoCD detects parameter change
- Automatically updates frontend deployment
- Backend continues running with old image (demo-123)
- Zero downtime deployment

## ❌ What you DON'T need to change:

- ✅ Chart.yaml version (stays 0.1.0)
- ✅ values.yaml in GitOps repo  
- ✅ Helm chart templates
- ✅ Backend image tag (if no backend changes)

## ✅ What changes:

- 🔄 ArgoCD Application parameter: `frontend.image.tag`
- 🔄 Kubernetes Deployment image reference
- 🔄 Running pod with new frontend image

## Example Scenario:

```yaml
# Before (both services running)
Frontend: acrnashpisharp.azurecr.io/nash-pisharp/frontend:demo-123
Backend:  acrnashpisharp.azurecr.io/nash-pisharp/backend:demo-123

# After (only frontend updated)  
Frontend: acrnashpisharp.azurecr.io/nash-pisharp/frontend:demo-456  ← NEW
Backend:  acrnashpisharp.azurecr.io/nash-pisharp/backend:demo-123   ← SAME

# Chart version: 0.1.0 (unchanged)
```

## CI/CD Integration:

```bash
# In your CI/CD pipeline for frontend changes:
# After building new frontend image:

# Update only frontend tag
argocd app set nash-pisharp-demo -p frontend.image.tag=${NEW_FE_TAG}

# Backend tag remains as-is
# Chart version unchanged
```

## Multiple Updates:

```bash
# If both FE & BE have new images:
./scripts/update-image-tags.sh demo new-fe-tag new-be-tag

# If only FE has new image:
argocd app set nash-pisharp-demo -p frontend.image.tag=new-fe-tag
# BE tag stays the same

# If only BE has new image:  
argocd app set nash-pisharp-demo -p backend.image.tag=new-be-tag
# FE tag stays the same
```