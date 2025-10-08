# Nash PiSharp GitOps - Quick Start Guide

## Prerequisites
- ✅ Kubernetes cluster ready
- ✅ Backend & Frontend images built and pushed to ACR/ECR
- ✅ kubectl configured

## Step 1: Install ArgoCD (5 minutes)

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access UI (run in separate terminal)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Step 2: Deploy Demo Application (2 minutes)

```bash
# Update image repository in values files if needed
# Edit: environments/demo/values.yaml - change registry if not using ACR

# Deploy ArgoCD project and demo app
kubectl apply -f argocd/nash-pisharp-project.yaml
kubectl apply -f argocd/nash-pisharp-demo.yaml
```

## Step 3: Update Image Tags (1 minute)

```bash
# Option 1: Use script
./scripts/update-image-tags.sh demo <your-backend-tag> <your-frontend-tag>

# Option 2: Manual via ArgoCD CLI
argocd app set nash-pisharp-demo -p backend.image.tag=<your-backend-tag>
argocd app set nash-pisharp-demo -p frontend.image.tag=<your-frontend-tag>

# Option 3: Via ArgoCD UI
# Go to https://localhost:8080 → nash-pisharp-demo → Edit → Parameters
```

## Step 4: Access Application (1 minute)

```bash
# Check deployment
kubectl get pods -n nash-pisharp-demo

# Access via port-forward
kubectl port-forward svc/nash-pisharp-frontend-service -n nash-pisharp-demo 3001:3000

# Open browser: http://localhost:3001
```

## Done! 🎉

Your demo environment is running at http://localhost:3001

---

## Notes

### Image Requirements
- **Backend**: Node.js app image pushed to your registry
- **Frontend**: React app image pushed to your registry  
- **Registry**: Update `image.registry` in `environments/demo/values.yaml` if not using `acrnashpisharp.azurecr.io`

### CI/CD Integration
```bash
# In your CI/CD pipeline, after building images:
argocd app set nash-pisharp-demo -p frontend.image.tag=${BUILD_NUMBER}
argocd app set nash-pisharp-demo -p backend.image.tag=${BUILD_NUMBER}
```

### Troubleshooting
```bash
# Check ArgoCD app status
kubectl get applications -n argocd

# Check demo pods
kubectl get pods -n nash-pisharp-demo

# Check logs
kubectl logs -f deployment/nash-pisharp-backend -n nash-pisharp-demo
```