# Glossary

| Term | Meaning | Software analogy (1 line) | Where it appears in this repo |
|---|---|---|---|
| kind | Kubernetes-in-Docker local cluster | Local VM for k8s API + nodes | `platform/kind/kind-config.yaml.tpl` |
| ingress | L7 entry router for HTTP host/path | Reverse proxy front door | `repos/infra/apps/demo/base/ingress.yaml` |
| overlay | Environment-specific Kustomize delta | Config profile on top of shared base | `repos/infra/apps/demo/overlays/local` |
| base | Shared manifests reused by envs | Abstract class for env configs | `repos/infra/apps/demo/base` |
| Argo Application | Argo CR describing a Git source to reconcile | Deployment subscription object | `repos/infra/bootstrap/demo-application.yaml` |
| GitOps | Cluster state driven from Git desired state | Declarative state machine with Git as input | `repos/infra` + `platform/scripts/argocd-*.sh` |
| image tag | Immutable image version pointer | Build artifact ID | `repos/app/scripts/image-tag.sh` |
| promotion | Moving a tested image tag to higher env overlay | Release pointer advance | `repos/infra/apps/demo/overlays/stage/kustomization.yaml` |
| registry mirror wiring | containerd config mapping registry endpoint | Package source override | `platform/scripts/up.sh` + `platform/manifests/local-registry-hosting-configmap.yaml` |
| Gitea Actions runner | Worker that executes workflows | Self-hosted CI executor | `repos/app/.gitea/workflows/deploy-main.yaml` |
| k8s dashboard token | Bearer token for dashboard login | Temporary API auth credential | `platform/scripts/k8s-dashboard-token.sh` |
