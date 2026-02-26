# gitops

Local end-to-end GitOps lab on macOS using Docker Desktop, kind, Gitea, Argo CD, and Kubernetes ingress.  
It includes an app repo (`repos/app`) and an infra repo (`repos/infra`) wired through Argo reconciliation.

## Repository model (submodules)

This root repository uses Git submodules:
- `repos/app` -> `gitops_app` (application code and image pipeline)
- `repos/infra` -> `gitops_infra` (Kubernetes desired state and overlays)

Clone with submodules:

```bash
git clone --recurse-submodules git@github.com:manuelro/gitops.git
cd gitops
```

If already cloned:

```bash
git submodule update --init --recursive
```

## Why this project exists

This workspace exists to practice production-like delivery loops locally:
- build/push app images
- promote image tags via infra Git
- let Argo CD reconcile desired state into Kubernetes

## What you will learn and do

- Bring up a local GitOps platform from scratch.
- Run dev flow: app push -> image build/push -> infra tag bump -> Argo sync.
- Run stage promotion flow: copy tested tag into stage overlay and deploy.
- Debug failures quickly using consistent checks and known signals.

## Quickstart (canonical)

### Requirements

- macOS + Docker Desktop (running)
- `kind` `>=0.20`
- `kubectl` `>=1.27`
- `argocd` CLI:
  - recommended local compatibility path in this repo:
    - `platform/.run/bin/argocd-v2.12.3`
- `curl`
- `k6` (for benchmark flows)

### Start dependencies

```bash
cd platform
make up
```

### Install/bootstrap Argo and repos

```bash
cd platform
make argo-up
```

### First successful end-to-end run

```bash
cd platform
make status
make check
make argo-check
```

Expected output shape:
- `make status`: running `gitops-gitea`, `kind-registry`, kind nodes `Ready`, Argo pods `Running`
- `make check`: ends with `All acceptance checks passed`
- `make argo-check`: ends with `Argo acceptance checks passed`

### Optional UIs

Kubernetes Dashboard (install once, then access):

```bash
cd platform
make k8s-dashboard-install
kubectl -n kubernetes-dashboard get pods
make k8s-dashboard-access     # https://127.0.0.1:10443
```

Argo CD UI/API access:

```bash
cd platform
make argo-access              # http://127.0.0.1:9080
```

### Auth for UIs

Argo CD admin password:

```bash
cd platform
make argo-admin-password
```

Kubernetes Dashboard login token:

```bash
cd platform
make k8s-dashboard-token
```

## Mental model (high-level pipeline)

```text
repos/app push (main)
  -> Gitea Actions workflow
  -> build/push demo-client + demo-api to local registry
  -> update repos/infra overlay tag(s)
  -> push infra commit
  -> Argo watches infra repo (desired state)
  -> sync to Kubernetes (kind)
  -> ingress routes traffic to updated pods
```

## Artifact locations

- Platform scripts and lifecycle: `platform/scripts`
- Platform manifests/templates: `platform/manifests`, `platform/kind`
- Load-test scripts: `platform/bench/k6`
- App source and image build logic: `repos/app`
- Infra desired state (Kustomize + Argo apps): `repos/infra`
- Runtime data/state: `platform/data`, `platform/.run`

## Sanity checks

```bash
# Local/dev env
curl -sI http://localhost:8081/ | head -n 1
curl -s http://localhost:8081/api/version

# Stage env (if enabled in infra bootstrap)
curl -sI http://stage.localtest.me:8081/ | head -n 1
curl -s http://stage.localtest.me:8081/api/version
```

Expected output shape:
- HTTP status line with `200`
- API JSON like `{"service":"demo-api","version":"v1"}`

## Troubleshooting (fast)

- `Argo app stays on old revision`:
  - run `kubectl -n argocd annotate app demo-local argocd.argoproj.io/refresh=hard --overwrite`
  - then `kubectl -n argocd get app demo-local`
- `Workflow stuck in Waiting`:
  - check Gitea Actions runner status and labels (`ubuntu-latest`)
- `Argo ComparisonError with Kustomize newTag`:
  - ensure tags are YAML strings, e.g. `newTag: "20260223025748"`
- `Registry push timeout`:
  - prefer `127.0.0.1:5001` in automation contexts

## Docs map

- System contract: `docs/architecture.md`
- ADRs: `docs/adr`
- Tutorial path: `docs/tutorial/00-index.md`
- Code navigation by goal: `docs/code-map.md`
- Glossary: `docs/glossary.md`
- Checkpoint runbook: `docs/learning-checkpoints.md`
