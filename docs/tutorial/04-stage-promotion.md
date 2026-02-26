# 04: Stage Promotion

## Objective
Promote a validated dev image tag into stage and verify stage routing.

## Prerequisites
- Chapter 03 complete
- `demo-stage` Argo app exists and is Healthy

## Mental model (developer analogy)
Promotion is a pointer update: same image artifact, different environment overlay.

## Theory (what’s happening and why it matters)
Stage uses a separate overlay (`apps/demo/overlays/stage`) and namespace (`demo-stage`). Changing `newTag` values there creates a promotion commit. Argo syncs stage independently from dev.

## Verification
### What this verifies
Environment isolation and explicit promotion discipline.

### Why it’s valuable
You can validate release candidates without rebuilding images.

### Run
```bash
# 1) pick a tag that exists for both images
curl -fsS http://localhost:5001/v2/demo-client/tags/list
curl -fsS http://localhost:5001/v2/demo-api/tags/list

# 2) update stage overlay tags
cd repos/infra
sed -n '1,200p' apps/demo/overlays/stage/kustomization.yaml

# 3) commit + push infra main
git add apps/demo/overlays/stage/kustomization.yaml
git commit -m "chore(stage): promote demo tag"
git push origin main

# 4) verify stage output
curl -sI http://stage.localtest.me:8081/ | head -n 1
curl -s http://stage.localtest.me:8081/api/version
```

### Expected output (shape)
- stage Argo app shows new target revision
- `demo-stage` deployment image reflects promoted tag
- stage hostname returns `HTTP/1.1 200`

### If it fails
- 404 on stage host: ingress host mismatch or stage app missing
- image pull errors: tag missing in registry
- app stuck OutOfSync: infra commit not pushed to origin

## Where the magic happens (follow the code)
- `repos/infra/apps/demo/overlays/stage/kustomization.yaml`
- `repos/infra/bootstrap/demo-stage-application.yaml`
- `repos/infra/apps/demo/base/ingress.yaml`

## Next
Continue to `docs/tutorial/05-fast-triage.md`.
