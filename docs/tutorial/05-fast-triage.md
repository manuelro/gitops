# 05: Fast Triage

## Objective
Diagnose the highest-frequency failures in under 60 seconds.

## Prerequisites
- Basic familiarity with chapters 01-04

## Mental model (developer analogy)
Always triage by layer: runtime -> GitOps controller -> repo state -> workload state -> routing.

## Theory (what’s happening and why it matters)
Most breakages come from one broken contract between adjacent layers. Fast checks identify the first broken contract instead of scanning random logs.

## Verification
### What this verifies
Each critical contract is currently satisfied.

### Why it’s valuable
Minimizes MTTR and avoids unnecessary restarts.

### Run
```bash
cd platform
make status
kubectl -n argocd get app
kubectl -n demo get deploy,pods,svc,ingress
kubectl -n demo-stage get deploy,pods,svc,ingress
curl -sI http://localhost:8081/ | head -n 1
curl -sI http://stage.localtest.me:8081/ | head -n 1
```

### Expected output (shape)
- runtime components running
- Argo apps `Healthy` and `Synced`
- deployments available replicas > 0
- both hosts return HTTP status line

### If it fails
- runtime missing: rerun `make up`
- Argo missing: rerun `make argo-up`
- app unhealthy: `kubectl describe pod` then inspect events
- route failing: check ingress rules and ingress-nginx logs

## Where the magic happens (follow the code)
- `platform/scripts/status.sh`
- `platform/scripts/argocd-check.sh`
- `repos/infra/apps/demo/base/*.yaml`
- `repos/infra/apps/demo/overlays/*/kustomization.yaml`

## Next
Use `docs/learning-checkpoints.md` as an operational drill sheet.

## Experiments
- Break a stage tag on purpose and observe failure signal.
- Disable runner and confirm dev automation stalls at Actions.
