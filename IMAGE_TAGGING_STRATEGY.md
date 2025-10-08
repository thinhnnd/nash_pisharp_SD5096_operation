# Image Tagging Strategy

## 🏷️ Nash PiSharp Image Naming Convention

### Branch-based Tagging Strategy

| Branch | Latest Tag | Versioned Tag | Usage |
|--------|------------|---------------|--------|
| **dev** | `dev-latest` | `dev-v1.0.{buildnum}` | Development environment |
| **main** | `latest` | `v1.0.{buildnum}` | Demo & Production |

## 📋 Environment Mapping

### Development Environment
- **Branch**: `dev`
- **Latest tag**: `dev-latest` 
- **Versioned**: `dev-v1.0.123`
- **Image examples**:
  ```
  acrnashpisharp.azurecr.io/nash-pisharp/frontend:dev-latest
  acrnashpisharp.azurecr.io/nash-pisharp/frontend:dev-v1.0.123
  acrnashpisharp.azurecr.io/nash-pisharp/backend:dev-latest
  acrnashpisharp.azurecr.io/nash-pisharp/backend:dev-v1.0.123
  ```

### Demo Environment  
- **Branch**: `main`
- **Tag**: `latest` (stable)
- **Versioned**: `v1.0.456`
- **Image examples**:
  ```
  acrnashpisharp.azurecr.io/nash-pisharp/frontend:latest
  acrnashpisharp.azurecr.io/nash-pisharp/frontend:v1.0.456
  acrnashpisharp.azurecr.io/nash-pisharp/backend:latest
  acrnashpisharp.azurecr.io/nash-pisharp/backend:v1.0.456
  ```

### Production Environment
- **Branch**: `main` 
- **Tag**: Specific versions (không dùng latest)
- **Versioned**: `v1.0.456`
- **Image examples**:
  ```
  acrnashpisharp.azurecr.io/nash-pisharp/frontend:v1.0.456
  acrnashpisharp.azurecr.io/nash-pisharp/backend:v1.0.456
  ```

## 🔄 CI/CD Pipeline Integration

### Dev Branch Pipeline
```yaml
# When code pushed to dev branch
trigger:
  branches:
    include:
    - dev

variables:
  imageTag: 'dev-v1.0.$(Build.BuildNumber)'
  latestTag: 'dev-latest'

steps:
- script: |
    # Build with versioned tag
    docker build -t $(ACR_NAME)/nash-pisharp/frontend:$(imageTag) ./frontend
    docker build -t $(ACR_NAME)/nash-pisharp/backend:$(imageTag) ./backend
    
    # Tag as latest
    docker tag $(ACR_NAME)/nash-pisharp/frontend:$(imageTag) $(ACR_NAME)/nash-pisharp/frontend:$(latestTag)
    docker tag $(ACR_NAME)/nash-pisharp/backend:$(imageTag) $(ACR_NAME)/nash-pisharp/backend:$(latestTag)
    
    # Push both tags
    docker push $(ACR_NAME)/nash-pisharp/frontend:$(imageTag)
    docker push $(ACR_NAME)/nash-pisharp/frontend:$(latestTag)
    docker push $(ACR_NAME)/nash-pisharp/backend:$(imageTag)  
    docker push $(ACR_NAME)/nash-pisharp/backend:$(latestTag)
```

### Main Branch Pipeline
```yaml
# When code pushed to main branch
trigger:
  branches:
    include:
    - main

variables:
  imageTag: 'v1.0.$(Build.BuildNumber)'
  latestTag: 'latest'

steps:
- script: |
    # Build with versioned tag
    docker build -t $(ACR_NAME)/nash-pisharp/frontend:$(imageTag) ./frontend
    docker build -t $(ACR_NAME)/nash-pisharp/backend:$(imageTag) ./backend
    
    # Tag as latest (for demo environment)
    docker tag $(ACR_NAME)/nash-pisharp/frontend:$(imageTag) $(ACR_NAME)/nash-pisharp/frontend:$(latestTag)
    docker tag $(ACR_NAME)/nash-pisharp/backend:$(imageTag) $(ACR_NAME)/nash-pisharp/backend:$(latestTag)
    
    # Push both tags
    docker push $(ACR_NAME)/nash-pisharp/frontend:$(imageTag)
    docker push $(ACR_NAME)/nash-pisharp/frontend:$(latestTag)
    docker push $(ACR_NAME)/nash-pisharp/backend:$(imageTag)
    docker push $(ACR_NAME)/nash-pisharp/backend:$(latestTag)
```

## 🎯 GitOps Environment Configuration

### Dev Environment (nash-pisharp-dev)
```yaml
# Uses dev-latest for continuous integration
frontend:
  image:
    tag: "dev-latest"
backend:
  image:
    tag: "dev-latest"
```

### Demo Environment (nash-pisharp-demo)  
```yaml
# Uses latest stable from main branch
frontend:
  image:
    tag: "latest"
backend:
  image:
    tag: "latest"
```

### Production Environment (nash-pisharp-prod)
```yaml
# Uses specific version tags (manual promotion)
frontend:
  image:
    tag: "v1.0.456"  # Specific tested version
backend:
  image:
    tag: "v1.0.456"  # Specific tested version
```

## 🔄 Deployment Scenarios

### Scenario 1: Development Cycle
1. Developer pushes to `dev` branch
2. CI builds images: `dev-v1.0.123` + `dev-latest`
3. ArgoCD auto-syncs dev environment with `dev-latest`
4. Development environment always has latest dev changes

### Scenario 2: Demo Updates
1. Developer merges PR to `main` branch  
2. CI builds images: `v1.0.456` + `latest`
3. ArgoCD auto-syncs demo environment with `latest`
4. Demo environment gets stable main branch changes

### Scenario 3: Production Deployment
1. Ops team decides to promote `v1.0.456` to production
2. Manual update: Change prod values from `v1.0.455` → `v1.0.456`
3. ArgoCD syncs production with specific version
4. Production runs tested, specific version

## 🛠️ Manual Version Updates

### Update Demo to Specific Version
```bash
# If you want demo to use specific version instead of latest
./scripts/update-image-tags.sh demo v1.0.456 v1.0.456
```

### Update Production  
```bash
# Production always uses specific versions
./scripts/update-image-tags.sh prod v1.0.456 v1.0.456
```

### Rollback Demo
```bash
# Rollback demo to previous version
./scripts/update-image-tags.sh demo v1.0.455 v1.0.455
```

## 📊 Benefits of This Strategy

1. **Development**: Always latest development changes via `dev-latest`
2. **Demo**: Stable main branch via `latest` 
3. **Production**: Controlled deployment via specific versions
4. **Traceability**: All versions tagged với build numbers
5. **Flexibility**: Can promote any version to any environment
6. **Safety**: Production never uses `latest` tags