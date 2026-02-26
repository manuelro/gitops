# 03: Dev Auto Deploy Flow

## Objective
Trigger end-to-end deploy from app `main` push and verify visible change in dev.

## Prerequisites
- Chapters 01 and 02 complete
- Gitea Actions runner online with label `ubuntu-latest`

## Mental model (developer analogy)
This is a two-repo relay race: app repo produces immutable image, infra repo records deploy intent, Argo applies it.

## Theory (what’s happening and why it matters)
On app push, workflow `deploy-main.yaml` runs `build-and-push.sh` then `promote-to-infra.sh`. The second script commits new tags into `repos/infra/apps/demo/overlays/local/kustomization.yaml`. Argo sees infra commit and rolls workloads.

## Verification
### What this verifies
Automation from app commit to Kubernetes rollout is working.

### Why it’s valuable
It proves deploy latency and control points before scaling changes.

### Run
```bash
# 1) change app text
cd repos/app
sed -n '1,120p' client/src/App.jsx

# 2) commit + push app main
git add client/src/App.jsx
git commit -m "feat(client): visible dev change"
git push origin main

# 3) observe workflow and infra tag bump
curl -s -u gitops-admin:change-me-local-2026 \
  http://localhost:3000/api/v1/repos/gitops/app/actions/runs?per_page=1

cd repos/infra
git log --oneline -n 3

# 4) verify deployed output
curl -s http://localhost:8081/
```

### Expected output (shape)
- latest action run completes successfully
- infra repo gets a `chore(demo): bump demo images to <tag>` commit
- homepage HTML includes your new client text

### If it fails
- run stuck `Waiting`: no runner/label mismatch
- infra unchanged: promotion script could not clone/push infra repo
- page unchanged: old image tag still deployed in `demo` namespace

## Where the magic happens (follow the code)
- `repos/app/.gitea/workflows/deploy-main.yaml`
- `repos/app/scripts/build-and-push.sh`
- `repos/app/scripts/promote-to-infra.sh`
- `repos/infra/apps/demo/overlays/local/kustomization.yaml`

## Next
Continue to `docs/tutorial/04-stage-promotion.md`.
