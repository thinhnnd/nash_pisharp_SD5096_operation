# Changelog

All notable changes to the Nash PiSharp GitOps repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-10-07

### Added
- Initial GitOps repository setup
- Helm charts integration from infrastructure repository
- Environment-specific values files (dev, staging, prod)
- ArgoCD applications for all environments
- ArgoCD ApplicationSet for centralized management
- ArgoCD project with RBAC configuration
- Automated deployment scripts (Bash and PowerShell)
- ArgoCD setup script
- Comprehensive documentation and README
- Git ignore configuration

### Features
- **Multi-environment support**: dev, staging, production
- **Automated deployments**: ArgoCD with GitOps workflow
- **Helm-based deployments**: Reusing existing Helm charts
- **Environment isolation**: Separate namespaces and configurations
- **Security controls**: Manual approval for production deployments
- **Scalability**: Horizontal Pod Autoscaler for staging and production
- **Monitoring ready**: Prometheus and Grafana configurations
- **TLS support**: Automated certificate management

### Infrastructure
- React.js frontend with configurable replicas and resources
- Node.js backend with environment-specific configurations
- MongoDB integration with external support for production
- Ingress configuration with SSL/TLS termination
- Resource management and limits per environment

### Security
- RBAC configuration for ArgoCD project
- Network policies ready
- Security contexts for containers
- External secret management support

## Repository Structure

```
nash_pisharp_SD5096_operation/
├── charts/nash-pisharp-app/     # Helm chart (from infrastructure repo)
├── environments/                # Environment-specific values
│   ├── dev/values.yaml
│   ├── staging/values.yaml
│   └── prod/values.yaml
├── argocd/                     # ArgoCD configurations
├── scripts/                    # Deployment and setup scripts
├── infrastructure/             # Shared infrastructure (future)
└── README.md                   # Documentation
```