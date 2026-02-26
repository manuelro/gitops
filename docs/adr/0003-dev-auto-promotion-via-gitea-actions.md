# ADR-0003: Dev Auto Promotion via Gitea Actions

**Status:** Accepted  
**Date:** 2026-02-25

## Decision
On `repos/app` push to `main`, run Gitea Actions to:
1. build/push `demo-client` and `demo-api` images,
2. update `repos/infra/apps/demo/overlays/local/kustomization.yaml` tags,
3. push infra commit.

## Context
Manual tag copy was slowing feedback loops and caused drift between built images and deployed tags.

## Options considered
| Option | Pros | Cons |
|---|---|---|
| Manual build + manual tag bump | Explicit control | Slow, error-prone |
| Image updater controller | Fully automated | Extra controller complexity for local lab |
| Gitea workflow + script promotion (chosen) | Simple, explicit, automation where needed | Depends on runner health |

## Decision drivers
- Keep automation inside existing local toolchain.
- Avoid introducing extra controllers before basics are stable.
- Keep infra commit history explicit.

## Consequences
Pros:
- App pushes become near end-to-end in one flow.
- Infra still remains source of truth.

Cons:
- Workflow can block on missing runners.

Mitigations:
- Clear runner label contract (`ubuntu-latest`) and diagnostics.

## Operational notes
- Workflow file: `repos/app/.gitea/workflows/deploy-main.yaml`
- Build/push: `repos/app/scripts/build-and-push.sh`
- Infra promotion: `repos/app/scripts/promote-to-infra.sh`

## Validation
```bash
curl -s -u gitops-admin:change-me-local-2026 \
  http://localhost:3000/api/v1/repos/gitops/app/actions/runs?per_page=3 | rg 'status|conclusion|head_sha' -n
```
Expected outcome shape:
- latest run appears for recent app commit
- final status is completed/success
