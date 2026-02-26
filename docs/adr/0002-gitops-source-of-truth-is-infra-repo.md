# ADR-0002: GitOps Source of Truth Is Infra Repository

**Status:** Accepted  
**Date:** 2026-02-25

## Decision
Argo CD reconciles only from `repos/infra` overlays, not from `repos/app`.

## Context
`repos/app` produces images. Kubernetes rollout intent (tag, resources, ingress, namespace) must remain declarative and auditable in infra Git.

## Options considered
| Option | Pros | Cons |
|---|---|---|
| Argo points to app repo | Fewer repos involved | Mixes app source with deployment intent |
| Direct `kubectl apply` from CI | Fast path | Loses GitOps reconciliation and drift control |
| Argo points to infra repo overlays (chosen) | Clear desired-state control and history | Requires tag promotion step |

## Decision drivers
- Deterministic reconciliation path.
- Explicit promotion by commit.
- Easy diff/review of runtime-impacting changes.

## Consequences
Pros:
- Infra commits are the deployment audit log.
- App and infra can move at different rates.

Cons:
- App push alone does not deploy until infra reflects the tag.

Mitigations:
- Auto-promotion script for local/dev flow.

## Operational notes
- `repos/infra/bootstrap/demo-application.yaml` -> local overlay.
- `repos/infra/bootstrap/demo-stage-application.yaml` -> stage overlay.

## Validation
```bash
kubectl -n argocd get app demo-local -o yaml | rg 'repoURL|path:' -n
```
Expected outcome shape:
- `repoURL` points to `/gitops/infra.git`
- `path` points to `apps/demo/overlays/local`
