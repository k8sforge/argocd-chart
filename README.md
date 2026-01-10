# ArgoCD Helm Chart

![Chart Releaser](https://github.com/k8sforge/argocd-chart/actions/workflows/chart-releaser.yml/badge.svg)

A Helm chart for deploying ArgoCD on Kubernetes. ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.

---

## Overview

This is a **reusable Helm chart repository**. The chart is versioned and published so it can be referenced by other repositories that deploy ArgoCD.

This chart wraps the official [ArgoCD Helm chart](https://github.com/argoproj/argo-helm) with sensible defaults and additional configurations including:

- **Automatic Argo Rollouts integration** - Rollout support configured automatically when enabled
- **Configurable health checks** - Platform-agnostic health check configuration for ingress
- **Prometheus monitoring** - ServiceMonitor for metrics scraping (optional)
- **High availability** - PodDisruptionBudget for production deployments (optional)
- **Resource management** - Sensible resource defaults for ArgoCD components
- **Generic ingress** - Platform-agnostic ingress configuration

---

## Chart Details

- **Chart Name**: `argocd`
- **Chart Version**: See [Chart.yaml](charts/argocd/Chart.yaml#L5)
- **App Version**: `latest` (ArgoCD image tag)
- **Dependencies**:
  - `argo-cd` (v7.0.0) from `https://argoproj.github.io/argo-helm`
  - `argo-rollouts` (v2.0.0) from `https://argoproj.github.io/argo-helm` (optional)

---

## Distribution

This chart is published in two formats:

- **OCI (ghcr.io)** – modern, registry-based installs
- **Helm repository (GitHub Pages)** – classic `helm repo add` workflow

Both distributions publish the same chart versions.

---

## Quick Start

### Install via OCI (recommended)

```bash
helm install my-argocd \
  oci://ghcr.io/k8sforge/argocd-chart/argocd \
  --version 0.1.0 \
  --namespace argocd \
  --create-namespace
```

If the registry is private:

```bash
helm registry login ghcr.io
```

---

### Install via Helm Repository (GitHub Pages)

```bash
helm repo add argocd https://k8sforge.github.io/argocd-chart
helm repo update

helm install my-argocd argocd/argocd --version 0.1.0 \
  --namespace argocd \
  --create-namespace
```

---

### Install from Source (local development)

```bash
# Update dependencies first
helm dependency update

# Install with default values
helm install my-argocd . \
  --namespace argocd \
  --create-namespace
```

---

## Prerequisites

- Kubernetes 1.20+
- `kubectl` configured
- Helm 3.x
- Ingress controller (AWS ALB, nginx, traefik, or platform-specific)
- Prometheus Operator (optional, for ServiceMonitor)

---

## Configuration

The following table lists the main configurable parameters:

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `argocd.enabled` | Enable ArgoCD installation | `true` |
| `argo-cd.server.service.type` | Service type | `ClusterIP` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.ingressClassName` | Ingress class name | `""` |
| `ingress.hosts` | Ingress hosts (empty = accept any) | `[]` |
| `healthCheck.enabled` | Enable health check annotations | `false` |
| `healthCheck.path` | Health check path | `"/healthz"` |
| `healthCheck.protocol` | Health check protocol | `"HTTP"` |
| `rollouts.enabled` | Enable Argo Rollouts (auto-configures ArgoCD) | `false` |
| `monitoring.serviceMonitor.enabled` | Enable ServiceMonitor for Prometheus | `false` |
| `podDisruptionBudget.enabled` | Enable PodDisruptionBudget for HA | `false` |
| `resources.*` | Resource requests/limits per component | See values.yaml |

See [values.yaml](charts/argocd/values.yaml) for the full configuration.

---

## Accessing ArgoCD

### Get Admin Password

After installation, retrieve the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Get ArgoCD Server URL

```bash
# Get the ingress URL
kubectl -n argocd get ingress -l app.kubernetes.io/name=argocd -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
```

### Login

```bash
# Using CLI
argocd login <argocd-server-url> --username admin --password <password>

# Or access via web UI
# Open http://<argocd-server-url> in your browser
```

---

## Health Checks

Health checks can be enabled to automatically add health check annotations to the ingress. This is platform-agnostic and works with any ingress controller.

### Enable Health Checks

```yaml
healthCheck:
  enabled: true
  path: "/healthz"
  protocol: "HTTP"
  port: "traffic-port"
```

When enabled, health check annotations are automatically added to the ingress. You can override or add platform-specific annotations in `ingress.annotations`.

### Platform-Specific Examples

**AWS ALB:**

```yaml
healthCheck:
  enabled: true
  path: "/healthz"
ingress:
  annotations:
    alb.ingress.kubernetes.io/healthcheck-path: "/healthz"
    alb.ingress.kubernetes.io/healthcheck-protocol: "HTTP"
```

**NGINX:**

```yaml
healthCheck:
  enabled: true
  path: "/healthz"
ingress:
  annotations:
    nginx.ingress.kubernetes.io/health-check-path: "/healthz"
```

---

## Argo Rollouts Integration

When `rollouts.enabled=true`, the chart automatically:

1. Installs Argo Rollouts controller
2. Configures ArgoCD to recognize Rollout resources
3. Adds custom health check Lua script for Rollout status evaluation

### Enable Rollouts

```yaml
rollouts:
  enabled: true
```

No additional configuration needed - Rollout support is automatically configured in ArgoCD.

### Rollout Health Check

The included health check Lua script evaluates Rollout status and reports:

- **Healthy**: When phase is "Healthy" or conditions indicate health
- **Progressing**: When rollout is in progress

### Verify Rollouts Installation

```bash
kubectl get pods -n argocd -l app.kubernetes.io/name=argo-rollouts
```

---

## Prometheus Monitoring

Enable ServiceMonitor for Prometheus metrics scraping:

```yaml
monitoring:
  serviceMonitor:
    enabled: true
    interval: "30s"
    scrapeTimeout: "10s"
    labels: {}
```

### Requirements

- Prometheus Operator must be installed in the cluster
- ServiceMonitor CRD must be available

### Verify ServiceMonitor

```bash
kubectl get servicemonitor -n argocd
```

---

## High Availability (PodDisruptionBudget)

Enable PodDisruptionBudget to ensure minimum availability during voluntary disruptions:

```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 1
  # Alternative: use maxUnavailable instead
  # maxUnavailable: 1
```

This prevents all ArgoCD server pods from being evicted simultaneously during node drains or updates.

---

## Resource Management

Default resource requests and limits are configured for ArgoCD components:

```yaml
resources:
  server:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  repoServer:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  applicationController:
    requests:
      memory: "128Mi"
      cpu: "50m"
    limits:
      memory: "256Mi"
      cpu: "200m"
```

These are passed to the official ArgoCD chart and can be overridden per component.

---

## Using This Chart from Another Repository (Repo B Pattern)

### Example dependency

```yaml
# Chart.yaml
apiVersion: v2
name: my-deployment
type: application
version: 1.0.0

dependencies:
  - name: argocd
    version: 0.1.0
    repository: https://k8sforge.github.io/argocd-chart
```

Then:

```bash
helm dependency update
helm upgrade --install my-argocd . -f values.yaml
```

> Note: Helm 3.8+ supports OCI-based dependencies, but classic repositories are shown here for maximum compatibility.

---

## Versioning and Releases

This chart follows semantic versioning.

To release a new version:

```bash
git tag v0.2.0
git push --tags
```

GitHub Actions will automatically publish the chart to:

- **GHCR (OCI)**
- **GitHub Pages (Helm repo)**

---

## Development

### Lint

```bash
helm lint charts/argocd
```

### Dry-run (requires cluster connection)

```bash
helm install my-argocd charts/argocd --dry-run --debug
```

### Render templates (no cluster required)

```bash
# Render templates without connecting to cluster
helm template my-argocd charts/argocd

# Or with custom values
helm template my-argocd charts/argocd -f values.yaml
```

### Update dependencies

```bash
helm dependency update
```

---

## Troubleshooting

### Check ArgoCD Server Status

```bash
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Check Ingress

```bash
kubectl get ingress -n argocd
kubectl describe ingress -n argocd
```

### Check Argo Rollouts

```bash
kubectl get pods -n argocd -l app.kubernetes.io/name=argo-rollouts
```

### Check ServiceMonitor

```bash
kubectl get servicemonitor -n argocd
```

### Check PodDisruptionBudget

```bash
kubectl get poddisruptionbudget -n argocd
```

### Verify Resource Customizations

```bash
kubectl get configmap argocd-cm -n argocd -o yaml
```

---

## License

MIT License. See LICENSE for details.

---

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Helm Chart](https://github.com/argoproj/argo-helm)
- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
