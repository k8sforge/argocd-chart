# ArgoCD Helm Chart Repository

![Auto Tag Release](https://github.com/k8sforge/argocd-chart/actions/workflows/chart-releaser.yml/badge.svg)

This is a Helm chart repository for the [ArgoCD](https://argo-cd.readthedocs.io/) Helm chart.

## Quick Start

### Add the Repository

```bash
helm repo add argocd https://k8sforge.github.io/argocd-chart
helm repo update
```

### Install the Chart

```bash
helm install my-argocd argocd/argocd --version <version>
```

### List Available Versions

```bash
helm search repo argocd/argocd --versions
```

## Chart Information

- **Chart Name**: `argocd`
- **Repository**: `https://k8sforge.github.io/argocd-chart`
- **Latest Version**: See [index.yaml](index.yaml) for available versions

## Documentation

For complete documentation, configuration options, and examples, visit the [main repository](https://github.com/k8sforge/argocd-chart).

## Alternative: OCI Installation

This chart is also available via OCI registry:

```bash
helm install my-argocd \
  oci://ghcr.io/k8sforge/argocd-chart/argocd \
  --version <version>
```

## Support

- **Issues**: [GitHub Issues](https://github.com/k8sforge/argocd-chart/issues)
- **Source Code**: [GitHub Repository](https://github.com/k8sforge/argocd-chart)
