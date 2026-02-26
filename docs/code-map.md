# Code Map

## Start here by goal
| Goal | Files in order | What to look for |
|---|---|---|
| Bring platform up/down | `platform/Makefile` -> `platform/scripts/up.sh` -> `platform/scripts/down.sh` | Lifecycle contracts and command surface |
| Understand Argo bootstrap | `platform/scripts/argocd-up.sh` -> `platform/scripts/argocd-bootstrap.sh` -> `repos/infra/bootstrap/kustomization.yaml` | How Argo app registration is applied |
| Trace app push to deploy | `repos/app/.gitea/workflows/deploy-main.yaml` -> `repos/app/scripts/build-and-push.sh` -> `repos/app/scripts/promote-to-infra.sh` -> `repos/infra/apps/demo/overlays/local/kustomization.yaml` | Build, tag, infra commit update path |
| Inspect runtime manifests | `repos/infra/apps/demo/base/kustomization.yaml` -> `deployment-client.yaml` -> `deployment-api.yaml` -> `ingress.yaml` | Pod shape, probes, routes, resources |
| Promote to stage | `repos/infra/apps/demo/overlays/stage/kustomization.yaml` -> `repos/infra/bootstrap/demo-stage-application.yaml` | Stage tag/host and Argo app binding |
| Run benchmark smoke | `platform/scripts/bench-preflight.sh` -> `platform/scripts/bench-spike.sh` -> `platform/scripts/bench-ramp.sh` | Load test preconditions and result location |

## Stage -> module map
| Stage | Primary files | Artifact | Debug signal |
|---|---|---|---|
| Platform bootstrap | `platform/scripts/up.sh` | kind cluster + registry + gitea + ingress | `kubectl get nodes` all Ready |
| Argo install/bootstrap | `platform/scripts/install-argocd.sh`, `platform/scripts/argocd-bootstrap.sh` | Argo deployment + bootstrap app manifest | `kubectl -n argocd get pods` Running |
| App build/push | `repos/app/scripts/build-and-push.sh` | `demo-client:<tag>`, `demo-api:<tag>` in local registry | `curl /v2/<name>/tags/list` contains tag |
| Infra promotion | `repos/app/scripts/promote-to-infra.sh` | infra commit bumping overlay tags | `git log` in infra shows bump commit |
| Reconciliation | `repos/infra/bootstrap/demo-application.yaml` | deployed resources in `demo`/`demo-stage` | Argo app Healthy/Synced |
| Edge serving | `repos/infra/apps/demo/base/ingress.yaml` | host/path routing to services | `curl` to host/path returns 200 |

## Where the magic happens
- `platform/scripts/up.sh:1` — orchestrates platform boot sequence.
- `platform/scripts/install-argocd.sh:1` — installs Argo version pinned in `.env`.
- `platform/scripts/argocd-repo-add.sh:1` — injects infra repo into Argo.
- `repos/app/scripts/image-tag.sh:1` — decides deploy tag strategy.
- `repos/app/scripts/build-and-push.sh:1` — builds and pushes both images.
- `repos/app/scripts/promote-to-infra.sh:1` — mutates infra Kustomize tags and pushes commit.
- `repos/app/.gitea/workflows/deploy-main.yaml:1` — trigger and CI runtime contract.
- `repos/infra/apps/demo/overlays/local/kustomization.yaml:1` — live dev image pointers.
- `repos/infra/apps/demo/overlays/stage/kustomization.yaml:1` — stage promotion pointer.
- `repos/infra/bootstrap/demo-application.yaml:1` — Argo source path for dev.
- `repos/infra/bootstrap/demo-stage-application.yaml:1` — Argo source path for stage.
