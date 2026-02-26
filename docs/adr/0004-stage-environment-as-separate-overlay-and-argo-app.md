# ADR-0004: Stage Environment as Separate Overlay and Argo Application

**Status:** Accepted  
**Date:** 2026-02-25

## Decision
Model stage as a separate infra overlay and Argo Application:
- overlay: `repos/infra/apps/demo/overlays/stage`
- app: `repos/infra/bootstrap/demo-stage-application.yaml`

## Context
Stage needs independent deploy state (namespace, host, tags) while reusing the same base manifests.

## Options considered
| Option | Pros | Cons |
|---|---|---|
| Single overlay for all envs | Minimal files | No environment isolation |
| Separate cluster for stage | Strong isolation | Heavy for local lab |
| Separate overlay + Argo app in same cluster (chosen) | Good isolation/cost balance | Need host/path separation |

## Decision drivers
- Keep promotion simple (tag copy/change in stage overlay).
- Preserve Kustomize reuse with environment deltas only.
- Maintain local resource footprint.

## Consequences
Pros:
- Dev and stage can run different tags simultaneously.
- Stage verification is explicit before further promotion.

Cons:
- Requires careful ingress hosts and namespaces.

Mitigations:
- Stage host set to `stage.localtest.me` in overlay patch.

## Operational notes
- `demo-local` and `demo-stage` both sync from infra `main`, different `path`.
- Stage promotion is done by editing stage `newTag` values.

## Validation
```bash
kubectl -n argocd get app demo-local demo-stage
kubectl -n demo get deploy demo-client -o=jsonpath='{.spec.template.spec.containers[0].image}'; echo
kubectl -n demo-stage get deploy demo-client -o=jsonpath='{.spec.template.spec.containers[0].image}'; echo
```
Expected outcome shape:
- both Argo apps exist and are Healthy/Synced
- image tags can differ between `demo` and `demo-stage`
