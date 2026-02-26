# local-gitops-e2e Architecture (System contract)

## What it is

`local-gitops-e2e` is a local GitOps workspace with:
- platform bootstrap/runtime (`platform/`)
- application source and image pipeline (`repos/app`)
- Kubernetes desired state (`repos/infra`)

It runs on macOS + Docker Desktop + kind and uses Gitea + Argo CD for Git-driven reconciliation.

## Goals

- Provide a reproducible local GitOps loop.
- Make app->infra->cluster flow observable and debuggable.
- Support explicit environment overlays (local + stage).
- Keep promotion artifact-based (image tags), not rebuild-based.

## Non-goals (for now)

- Multi-region or cloud-managed clusters.
- External managed registry/Git providers.
- Production security hardening (secrets management, SSO, RBAC policy bundles).
- Full CI matrix and release orchestration beyond local Gitea Actions runner.

## Pipelines (high level)

```text
Platform bootstrap
  make up
    -> docker compose (gitea + registry)
    -> kind cluster
    -> ingress-nginx

GitOps bootstrap
  make argo-up
    -> install Argo CD
    -> add infra repo secret
    -> apply infra-bootstrap Application

Dev auto-deploy
  repos/app push main
    -> .gitea/workflows/deploy-main.yaml
    -> scripts/build-and-push.sh
    -> scripts/promote-to-infra.sh (overlay=local)
    -> infra commit pushed
    -> Argo sync demo-local

Stage promotion
  manual infra tag update in overlays/stage
    -> infra commit pushed
    -> Argo sync demo-stage
```

## Artifacts and where they live

| Artifact | Path | Produced by | Used by | Why it matters |
|---|---|---|---|---|
| Platform lifecycle commands | `platform/Makefile` | Engineers | Local operators | Single command surface for up/down/check/access |
| Kind config (generated) | `platform/kind/kind-config.generated.yaml` | `platform/scripts/up.sh` | `kind create cluster` | Defines registry mirror + node topology |
| Argo bootstrap app manifest (generated) | `platform/manifests/bootstrap-app.generated.yaml` | `platform/scripts/argocd-bootstrap.sh` | Argo API/K8s | Connects Argo to infra bootstrap path |
| App image tags | local registry (`localhost:5001`) | `repos/app/scripts/build-and-push.sh` | K8s deployments | Immutable deploy artifact |
| Dev desired state | `repos/infra/apps/demo/overlays/local/kustomization.yaml` | app workflow + engineers | Argo `demo-local` | Declares running image in dev/local |
| Stage desired state | `repos/infra/apps/demo/overlays/stage/kustomization.yaml` | Engineers | Argo `demo-stage` | Promotion target for tested tag |
| Argo Applications | `repos/infra/bootstrap/*.yaml` | Engineers | Argo | Declarative app registration (`demo-local`, `demo-stage`) |
| Workflow run logs | `platform/data/gitea/gitea/actions_log/...` | Gitea Actions | Engineers | Root cause for CI failures |

## Key invariants

| Invariant | Why true | What to do if broken |
|---|---|---|
| Argo deploys from `repos/infra`, not `repos/app` | `bootstrap/demo-application.yaml` and `demo-stage-application.yaml` source paths point to infra overlays | Verify Argo app `source.repoURL/path`; refresh app |
| Image tags in Kustomize must be strings | Kustomize unmarshals `newTag` as string | Quote values: `newTag: "..."` |
| Dev auto-promotion writes only local overlay | `repos/app/scripts/promote-to-infra.sh` default `INFRA_OVERLAY=local` | Set `INFRA_OVERLAY` intentionally or promote stage manually |
| Workflow requires runner label match | `.gitea/workflows/deploy-main.yaml` uses `runs-on: ubuntu-latest` | Ensure runner is online with `ubuntu-latest` label |
| Registry endpoint behavior differs by context | Docker daemon path stability can differ for `localhost` vs `127.0.0.1` | Use `127.0.0.1:5001` in automation if timeout occurs |

## Common failure modes

| Symptom | Likely cause | Fast check | Fix |
|---|---|---|---|
| App UI unchanged after app push | Infra tag not updated/synced yet | `kubectl -n demo get deploy demo-client -o=jsonpath='{.spec.template.spec.containers[0].image}'` | Verify workflow success and infra commit; refresh Argo |
| Workflow run `Waiting` forever | No runner or label mismatch | Gitea Actions page + runner status | Register/start runner with `ubuntu-latest` label |
| Argo `ComparisonError` for `newTag` | Numeric unquoted tag in YAML | `kubectl -n argocd get app demo-local -o yaml | rg ComparisonError -n` | Quote tag values and push infra fix |
| `argocd` CLI login/check fails | Client/server version mismatch | `argocd version --client` and server version | Use compatible CLI (`platform/.run/bin/argocd-v2.12.3`) |
| Stage host returns 404 | Stage app not bootstrapped or not synced | `kubectl -n argocd get app demo-stage` | Ensure stage bootstrap manifest is in infra and synced |

## Code entrypoints (read first)

- Platform bootstrap flow: `platform/scripts/up.sh`
- Argo install/bootstrap: `platform/scripts/install-argocd.sh`, `platform/scripts/argocd-up.sh`
- Acceptance checks: `platform/scripts/checks.sh`, `platform/scripts/argocd-check.sh`
- App build/publish: `repos/app/scripts/build-and-push.sh`
- Infra promotion logic: `repos/app/scripts/promote-to-infra.sh`
- Auto-deploy workflow: `repos/app/.gitea/workflows/deploy-main.yaml`
- Environment overlays: `repos/infra/apps/demo/overlays/*/kustomization.yaml`
- Argo apps registry: `repos/infra/bootstrap/*.yaml`

## ADR index

- `docs/adr/0001-workspace-shape-and-repo-boundaries.md`
- `docs/adr/0002-gitops-source-of-truth-is-infra-repo.md`
- `docs/adr/0003-dev-auto-promotion-via-gitea-actions.md`
- `docs/adr/0004-stage-environment-as-separate-overlay-and-argo-app.md`

## Updating locked decisions

- ADRs are append-only.
- Never rewrite accepted ADRs in place.
- If a decision changes, create a new ADR and mark old ADR as superseded.
