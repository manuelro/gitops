# 02: Argo CD Bootstrap

## Objective
Install Argo CD, register the infra repo, and bootstrap Argo Applications.

## Prerequisites
- Chapter 01 complete
- Gitea reachable at `http://localhost:3000`

## Mental model (developer analogy)
Argo is your deployment reconciler loop that keeps cluster state aligned to infra Git.

## Theory (what’s happening and why it matters)
`make argo-up` installs Argo, logs in with admin credentials, adds the infra Git repo, and applies a bootstrap `Application` that creates environment apps (`demo-local`, `demo-stage`).

## Verification
### What this verifies
GitOps controller is running and can read desired state.

### Why it’s valuable
Without repo connectivity, auto-sync and promotion flows cannot work.

### Run
```bash
cd platform
make argo-up
make argo-check
make argo-access
```

### Expected output (shape)
- `argocd` namespace pods are `Running`
- repo add/get succeeds
- Argo UI responds on `http://127.0.0.1:9080`

### If it fails
- repo add DNS/connection errors: validate `host.docker.internal` from a test pod
- CLI mismatch: use `platform/.run/bin/argocd-v2.12.3`
- login failure: regenerate password via `make argo-admin-password`

## Where the magic happens (follow the code)
- `platform/scripts/install-argocd.sh`
- `platform/scripts/argocd-repo-add.sh`
- `platform/scripts/argocd-bootstrap.sh`
- `repos/infra/bootstrap/kustomization.yaml`

## Next
Continue to `docs/tutorial/03-dev-auto-deploy.md`.
