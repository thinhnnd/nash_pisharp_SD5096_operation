# Azure DevOps Service Connection Setup for AKS

## Overview

Để CD pipeline có thể deploy lên AKS, bạn cần tạo Kubernetes Service Connection trong Azure DevOps.

## Prerequisites

1. **Azure DevOps Project** với quyền admin
2. **AKS Cluster** đang chạy
3. **ArgoCD** đã được cài đặt trên cluster

## Setup Service Connection

### Option 1: Sử dụng Azure Resource Manager (Recommended)

1. **Go to Project Settings**:
   - Azure DevOps → Project Settings → Service connections

2. **Create New Service Connection**:
   - Click "New service connection"
   - Select "Kubernetes"
   - Choose "Azure Resource Manager"

3. **Configure Connection**:
   - **Subscription**: Chọn subscription chứa AKS
   - **Cluster**: Chọn AKS cluster (`aks-nash-pisharp`)
   - **Namespace**: Để trống (pipeline sẽ specify)
   - **Service connection name**: `aks-connection`

4. **Verify and Save**:
   - Click "Verify" để test connection
   - Save service connection

### Option 2: Sử dụng Service Account (Advanced)

1. **Create Service Account**:
```bash
# Create service account for Azure DevOps
kubectl create serviceaccount azure-devops-deploy -n kube-system

# Create cluster role binding
kubectl create clusterrolebinding azure-devops-deploy \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:azure-devops-deploy
```

2. **Get Service Account Token**:
```bash
# Get secret name
SECRET_NAME=$(kubectl get serviceaccount azure-devops-deploy -n kube-system -o jsonpath='{.secrets[0].name}')

# Get token
TOKEN=$(kubectl get secret $SECRET_NAME -n kube-system -o jsonpath='{.data.token}' | base64 --decode)

# Get cluster URL
CLUSTER_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

echo "Cluster URL: $CLUSTER_URL"
echo "Token: $TOKEN"
```

3. **Create Service Connection in Azure DevOps**:
   - Type: Kubernetes
   - Authentication method: Service Account
   - Server URL: `$CLUSTER_URL`
   - Secret: `$TOKEN`

## Update Pipeline Configuration

### If using different service connection name:

```yaml
# In azure-pipelines-cd.yml, add this step before deployment:
- task: KubernetesManifest@0
  displayName: 'Set Kubernetes Context'
  inputs:
    action: 'deploy'
    kubernetesServiceConnection: 'your-connection-name'  # Update this
```

### Current pipeline assumes:
- Service connection is properly configured
- kubectl can access the cluster
- No explicit connection name needed (uses default)

## Verify Setup

### Test Connection:
```bash
# Run this from your local machine or build agent
kubectl cluster-info
kubectl get ns argocd
kubectl get pods -n argocd
```

### Expected Output:
```
Kubernetes control plane is running at https://aks-nash-pisharp-xxxxx.hcp.eastus.azmk8s.io:443

NAME     STATUS   AGE
argocd   Active   6h

NAME                                               READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                    1/1     Running   0          6h
argocd-applicationset-controller-xxx               1/1     Running   0          6h
argocd-dex-server-xxx                             1/1     Running   0          6h
argocd-notifications-controller-xxx                1/1     Running   0          6h
argocd-redis-xxx                                  1/1     Running   0          6h
argocd-repo-server-xxx                            1/1     Running   0          6h
argocd-server-xxx                                 1/1     Running   0          6h
```

## ArgoCD Access (Optional)

Nếu bạn muốn access ArgoCD UI từ bên ngoài:

### Option 1: Port Forward
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Access: https://localhost:8080
```

### Option 2: LoadBalancer Service
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc argocd-server -n argocd
```

### Option 3: Ingress (với Load Balancer)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
spec:
  rules:
  - host: argocd.your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
```

## ArgoCD Initial Setup

### Get Admin Password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Default Login:
- Username: `admin`
- Password: (from command above)

## Troubleshooting

### Common Issues:

| Issue | Solution |
|-------|----------|
| Service connection fails | Check AKS cluster status and permissions |
| kubectl not found | Install kubectl on build agent |
| Permission denied | Verify service account has correct RBAC |
| ArgoCD not found | Check ArgoCD installation in 'argocd' namespace |
| Network timeout | Check AKS network rules and firewall |

### Debug Commands:
```bash
# Check service connection
az aks get-credentials --resource-group rg-nash-pisharp-demo --name aks-nash-pisharp

# Test kubectl
kubectl cluster-info
kubectl auth can-i '*' '*' --all-namespaces

# Check ArgoCD
kubectl get all -n argocd
kubectl logs -n argocd deployment/argocd-server
```

## Security Best Practices

1. **Least Privilege**: Create specific service account with minimal permissions
2. **Token Rotation**: Regularly rotate service account tokens
3. **Network Security**: Use private endpoints if possible
4. **Audit Logging**: Enable Kubernetes audit logging
5. **RBAC**: Use Role-Based Access Control instead of cluster-admin

## Next Steps

1. **Test Service Connection** in Azure DevOps
2. **Run CD Pipeline** with a test change
3. **Monitor Deployment** in ArgoCD UI
4. **Verify Applications** are running correctly