# Usage Examples

This document provides practical examples of how to use the ArgoCD Helm chart.

## Table of Contents

1. [Basic Installation](#basic-installation)
2. [Installation with Custom Values](#installation-with-custom-values)
3. [Installation from OCI Registry](#installation-from-oci-registry)
4. [Health Check Configuration](#health-check-configuration)
5. [Argo Rollouts with Automatic Configuration](#argo-rollouts-with-automatic-configuration)
6. [Prometheus Monitoring](#prometheus-monitoring)
7. [High Availability with PodDisruptionBudget](#high-availability-with-poddisruptionbudget)
8. [Resource Management](#resource-management)
9. [AWS ALB Example](#aws-alb-example)
10. [NGINX Ingress Example](#nginx-ingress-example)
11. [Using as a Dependency](#using-as-a-dependency)
12. [Accessing ArgoCD](#accessing-argocd)

---

## Basic Installation

### Install from Local Chart

```bash
# Clone the repository
git clone https://github.com/k8sforge/argocd-chart.git
cd argocd-chart

# Update dependencies
helm dependency update

# Install with default values
helm install my-argocd . \
  --namespace argocd \
  --create-namespace
```

### Install with Override Values

```bash
# Install and override specific values
helm install my-argocd . \
  --namespace argocd \
  --create-namespace \
  --set ingress.ingressClassName=alb \
  --set rollouts.enabled=true \
  --set healthCheck.enabled=true
```

---

## Installation with Custom Values

### Create a Custom Values File

Create `my-argocd-values.yaml`:

```yaml
# my-argocd-values.yaml
argocd:
  enabled: true

argo-cd:
  server:
    service:
      type: ClusterIP
      port: 80
    insecure: true

ingress:
  enabled: true
  ingressClassName: "alb"
  hosts: []
  annotations: {}

healthCheck:
  enabled: true
  path: "/healthz"
  protocol: "HTTP"
  port: "traffic-port"

rollouts:
  enabled: true # Installs controller AND configures ArgoCD

# Optional: Customize Rollouts controller settings
argo-rollouts:
  # Leave empty for defaults
```

### Install with Custom Values

```bash
# Update dependencies first
helm dependency update

# Install with custom values
helm install my-argocd . \
  -f my-argocd-values.yaml \
  --namespace argocd \
  --create-namespace
```

---

## Installation from OCI Registry

If the chart is published to an OCI registry (like GitHub Container Registry):

```bash
# For OCI registries, use direct reference (no helm repo add needed)
helm install my-argocd \
  oci://ghcr.io/k8sforge/argocd-chart/argocd \
  --version 0.1.0 \
  --namespace argocd \
  --create-namespace

# Or with custom values
helm install my-argocd \
  oci://ghcr.io/k8sforge/argocd-chart/argocd \
  --version 0.1.0 \
  -f my-argocd-values.yaml \
  --namespace argocd \
  --create-namespace

# Alternative: If published to a traditional Helm repository
helm repo add argocd https://k8sforge.github.io/argocd-chart
helm repo update
helm install my-argocd argocd/argocd --version 0.1.0 \
  --namespace argocd \
  --create-namespace
```

---

## Health Check Configuration

### Enable Health Checks

Health checks automatically add annotations to the ingress:

```yaml
# health-check-values.yaml
healthCheck:
  enabled: true
  path: "/healthz"
  protocol: "HTTP"
  port: "traffic-port"

ingress:
  enabled: true
  ingressClassName: "alb"
  hosts: []
  # Platform-specific annotations can be added here
  annotations:
    alb.ingress.kubernetes.io/scheme: "internet-facing"
    alb.ingress.kubernetes.io/target-type: "ip"
```

### Disable Health Checks

```yaml
healthCheck:
  enabled: false

ingress:
  enabled: true
  annotations:
    # Add custom annotations manually
    custom-annotation: "value"
```

---

## Argo Rollouts with Automatic Configuration

### Enable Rollouts (Automatic Installation and Configuration)

When `rollouts.enabled=true`, the chart will:

1. **Install** the Argo Rollouts controller (via Helm dependency)
2. **Configure** ArgoCD to support Rollout resources automatically

```yaml
# rollouts-values.yaml
rollouts:
  enabled: true

# Optional: Configure Argo Rollouts controller
argo-rollouts:
  # Leave empty for defaults, or customize:
  # image:
  #   tag: "v2.40.5"
  # resources:
  #   limits:
  #     memory: "256Mi"
  #     cpu: "200m"

argo-cd:
  server:
    insecure: true
  configs:
    params:
      "server.insecure": "true"
```

**Note:** You do NOT need to install Argo Rollouts separately when using this chart. The chart handles both installation and configuration automatically.

### Verify Rollouts Installation and Configuration

```bash
# Check that Rollout controller is installed
kubectl get pods -n argocd -l app.kubernetes.io/name=argo-rollouts

# Check that Rollout configs were applied to ArgoCD
kubectl get configmap argocd-cm -n argocd -o yaml | grep -A 5 "application.types"

# Should show: application.types: rollout.argoproj.io

# Verify the controller is managing Rollouts
kubectl get rollouts -A
```

---

## Prometheus Monitoring

### Enable ServiceMonitor

```yaml
# monitoring-values.yaml
monitoring:
  serviceMonitor:
    enabled: true
    interval: "30s"
    scrapeTimeout: "10s"
    labels:
      release: prometheus
```

### Verify ServiceMonitor

```bash
# Check ServiceMonitor was created
kubectl get servicemonitor -n argocd

# Check if Prometheus is scraping
# (requires Prometheus Operator and Prometheus instance)
```

---

## High Availability with PodDisruptionBudget

### Enable PodDisruptionBudget

```yaml
# ha-values.yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 1
```

### Alternative: Use maxUnavailable

```yaml
podDisruptionBudget:
  enabled: true
  maxUnavailable: 1
```

### Verify PodDisruptionBudget

```bash
kubectl get poddisruptionbudget -n argocd
```

---

## Resource Management

### Customize Resource Limits

```yaml
# resources-values.yaml
resources:
  server:
    requests:
      memory: "512Mi"
      cpu: "200m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
  repoServer:
    requests:
      memory: "512Mi"
      cpu: "200m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
  applicationController:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"
```

These values are passed to the official ArgoCD chart.

---

## AWS ALB Example

Complete example for AWS EKS with ALB Ingress Controller:

```yaml
# aws-alb-values.yaml
argocd:
  enabled: true

argo-cd:
  server:
    service:
      type: ClusterIP
      port: 80
    insecure: true

ingress:
  enabled: true
  ingressClassName: "alb"
  hosts: []
  annotations:
    alb.ingress.kubernetes.io/scheme: "internet-facing"
    alb.ingress.kubernetes.io/target-type: "ip"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/backend-protocol: "HTTP"

healthCheck:
  enabled: true
  path: "/healthz"
  protocol: "HTTP"
  port: "traffic-port"

rollouts:
  enabled: true # Installs controller AND configures ArgoCD

# Optional: Customize Rollouts controller settings
argo-rollouts:
  # Leave empty for defaults

monitoring:
  serviceMonitor:
    enabled: true

podDisruptionBudget:
  enabled: true
  minAvailable: 1
```

Install:

```bash
helm dependency update
helm install my-argocd . \
  -f aws-alb-values.yaml \
  --namespace argocd \
  --create-namespace
```

---

## NGINX Ingress Example

Example for NGINX Ingress Controller with cert-manager:

```yaml
# nginx-values.yaml
argocd:
  enabled: true

argo-cd:
  server:
    service:
      type: ClusterIP
      port: 80
    insecure: false

ingress:
  enabled: true
  ingressClassName: "nginx"
  hosts:
    - host: argocd.example.com
      paths:
        - path: /
          pathType: Prefix
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/limit-rps: "100"
  tls:
    - secretName: argocd-tls
      hosts:
        - argocd.example.com

healthCheck:
  enabled: true
  path: "/healthz"

rollouts:
  enabled: true # Installs controller AND configures ArgoCD

# Optional: Customize Rollouts controller settings
argo-rollouts:
  # Leave empty for defaults
```

Install:

```bash
helm dependency update
helm install my-argocd . \
  -f nginx-values.yaml \
  --namespace argocd \
  --create-namespace
```

---

## Using as a Dependency

If you have a deployment repository that uses this chart as a dependency:

### 1. Create Chart.yaml in your deployment repo

```yaml
# Chart.yaml
apiVersion: v2
name: my-service-deploy
description: Deployment configuration for my service
type: application
version: 1.0.0

dependencies:
  - name: argocd
    version: 0.1.0
    repository: https://k8sforge.github.io/argocd-chart
```

### 2. Create values.yaml

```yaml
# values.yaml
argocd:
  enabled: true

argo-cd:
  server:
    insecure: true

ingress:
  enabled: true
  ingressClassName: "alb"
  hosts: []

healthCheck:
  enabled: true

rollouts:
  enabled: true # Installs controller AND configures ArgoCD

# Optional: Customize Rollouts controller settings
argo-rollouts:
  # Leave empty for defaults

monitoring:
  serviceMonitor:
    enabled: true

podDisruptionBudget:
  enabled: true
```

### 3. Install

```bash
# Update dependencies
helm dependency update

# Install
helm install my-argocd . \
  -f values.yaml \
  --namespace argocd \
  --create-namespace
```

---

## Accessing ArgoCD

### Get Admin Password

After installation, retrieve the initial admin password:

```bash
# Get the password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Or using argocd CLI (if installed)
argocd admin initial-password -n argocd
```

### Get ArgoCD Server URL

```bash
# Get the ingress URL (ALB DNS name)
kubectl -n argocd get ingress \
  -l app.kubernetes.io/name=argocd \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'

# Or get the full ingress details
kubectl -n argocd get ingress -o yaml
```

### Login via CLI

```bash
# Get the server URL
ARGOCD_SERVER=$(kubectl -n argocd get ingress \
  -l app.kubernetes.io/name=argocd \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

# Get the password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

# Login
argocd login $ARGOCD_SERVER \
  --username admin \
  --password $ARGOCD_PASSWORD \
  --insecure  # Required when using insecure mode
```

### Access Web UI

1. Get the server URL:

   ```bash
   kubectl -n argocd get ingress \
     -l app.kubernetes.io/name=argocd \
     -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
   ```

2. Open in browser: `http://<server-url>`

3. Login with:
   - Username: `admin`
   - Password: (from secret above)

---

## Complete Production Example

Full production configuration with all features enabled:

```yaml
# production-values.yaml
argocd:
  enabled: true

argo-cd:
  server:
    service:
      type: ClusterIP
      port: 80
    insecure: true
  configs:
    params:
      "server.insecure": "true"

ingress:
  enabled: true
  ingressClassName: "alb"
  hosts: []
  annotations:
    alb.ingress.kubernetes.io/scheme: "internet-facing"
    alb.ingress.kubernetes.io/target-type: "ip"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/backend-protocol: "HTTP"

healthCheck:
  enabled: true
  path: "/healthz"
  protocol: "HTTP"
  port: "traffic-port"

rollouts:
  enabled: true

# Optional: Production-ready Rollouts controller settings
argo-rollouts:
  image:
    tag: "v2.40.5"
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"

monitoring:
  serviceMonitor:
    enabled: true
    interval: "30s"
    scrapeTimeout: "10s"
    labels:
      release: prometheus

podDisruptionBudget:
  enabled: true
  minAvailable: 1

resources:
  server:
    requests:
      memory: "512Mi"
      cpu: "200m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
  repoServer:
    requests:
      memory: "512Mi"
      cpu: "200m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
  applicationController:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"
```

---

## Upgrade and Rollback

### Upgrade

```bash
# Upgrade with new values
helm upgrade my-argocd . -f my-argocd-values.yaml

# Upgrade with new chart version from OCI registry
helm upgrade my-argocd \
  oci://ghcr.io/k8sforge/argocd-chart/argocd \
  --version 0.2.0 \
  --namespace argocd
```

### Rollback

```bash
# Check release history
helm history my-argocd -n argocd

# Rollback to previous version
helm rollback my-argocd -n argocd

# Rollback to specific revision
helm rollback my-argocd 3 -n argocd
```

---

## Troubleshooting

### Check ArgoCD Server Status

```bash
# Check pods
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server

# Check logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=100

# Check all ArgoCD components
kubectl get pods -n argocd
```

### Check Service

```bash
kubectl get svc -n argocd
kubectl describe svc argocd-server -n argocd
```

### Check Ingress

```bash
# Get ingress details
kubectl get ingress -n argocd
kubectl describe ingress -n argocd

# Check ingress events
kubectl get events -n argocd --field-selector involvedObject.kind=Ingress
```

### Check Argo Rollouts

```bash
# Check rollouts controller (installed by chart when rollouts.enabled=true)
kubectl get pods -n argocd -l app.kubernetes.io/name=argo-rollouts

# Check rollouts logs
kubectl logs -n argocd -l app.kubernetes.io/name=argo-rollouts

# Verify the controller is managing Rollouts
kubectl get rollouts -A
```

### Check ServiceMonitor

```bash
kubectl get servicemonitor -n argocd
kubectl describe servicemonitor -n argocd
```

### Check PodDisruptionBudget

```bash
kubectl get poddisruptionbudget -n argocd
kubectl describe poddisruptionbudget -n argocd
```

### Verify Resource Customizations

```bash
# Check ArgoCD configmap
kubectl get configmap argocd-cm -n argocd -o yaml

# Check if Rollout customizations are present
kubectl get configmap argocd-cm -n argocd \
  -o jsonpath='{.data.application\.types}'
```

### Validate Chart

```bash
# Lint
helm lint .

# Dry-run
helm install my-argocd . --dry-run --debug -n argocd

# Template rendering
helm template my-argocd . -f values.yaml
```

---

## Next Steps

1. **Access ArgoCD UI** using the admin credentials
2. **Configure repositories** to connect to your Git repositories
3. **Create applications** to deploy your workloads
4. **Set up RBAC** for team access control
5. **Configure SSO** if needed (requires HTTPS)
6. **Monitor ArgoCD** using Prometheus metrics (if ServiceMonitor enabled)
7. **Test high availability** by draining nodes (if PodDisruptionBudget enabled)
