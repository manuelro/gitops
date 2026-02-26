# 01: Platform Bring-Up

## Objective
Start the local platform (registry, Gitea, kind, ingress) and confirm baseline health.

## Prerequisites
- Docker Desktop running
- `kind`, `kubectl`, `curl` on PATH

## Mental model (developer analogy)
This is your local cloud substrate: networking, cluster, and control plane dependencies before app deploy exists.

## Theory (what’s happening and why it matters)
`make up` in `platform/` starts Docker services, creates kind, wires registry mirror, and installs ingress. Without this, Argo and workloads cannot reconcile or route traffic.

## Verification
### What this verifies
Core infrastructure is alive and reachable.

### Why it’s valuable
It isolates runtime failures before adding GitOps complexity.

### Run
```bash
cd platform
make up
make status
make check
```

### Expected output (shape)
- `docker ps` includes `gitops-gitea` and `kind-registry`
- kind nodes report `Ready`
- ingress controller pods are `Running`
- check script ends with success message

### If it fails
- `Cannot connect to Docker daemon`: start Docker Desktop
- kind create fails: `kind delete cluster --name gitops-local` then `make up`
- ingress timeout: `kubectl -n ingress-nginx get pods -w`

## Where the magic happens (follow the code)
- `platform/scripts/up.sh`
- `platform/scripts/install-ingress.sh`
- `platform/scripts/checks.sh`
- `platform/kind/kind-config.yaml.tpl`

## Next
Continue to `docs/tutorial/02-argocd-bootstrap.md`.
