# Platform Foundation (macOS + Docker Desktop + kind)

This module provisions a local GitOps platform foundation with:

- Local Docker registry (`localhost:5001` by default)
- kind cluster wired to the local registry mirror
- ingress-nginx installed for kind
- Gitea running in Docker and reachable from cluster pods through `host.docker.internal`
- Argo CD installed in-cluster with deterministic initial access

## Defaults

Defaults are defined in `.env`:

- `WORKSPACE_ROOT=local-gitops-e2e`
- `KIND_CLUSTER_NAME=gitops-local`
- `LOCAL_REGISTRY_HOST=localhost`
- `LOCAL_REGISTRY_PORT=5001`
- `GITEA_HTTP_PORT=3000`
- `GITEA_SSH_PORT=2222`
- `GITEA_URL_FROM_HOST=http://localhost:3000`
- `GITEA_URL_FROM_CLUSTER=http://host.docker.internal:3000`
- `GITEA_ADMIN_USERNAME=gitops-admin`
- `GITEA_ADMIN_PASSWORD=admin12345`
- `GITEA_ADMIN_EMAIL=admin@example.local`
- `ARGO_NAMESPACE=argocd`
- `ARGO_EXPOSE_METHOD=port-forward` (`port-forward` or `ingress`)
- `ARGOCD_VERSION=v2.12.3`
- `ARGO_INGRESS_HOST=argocd.localtest.me`
- `ARGOCD_PORT_FORWARD_PORT=9080`
- `GITEA_REPO_HOST_FROM_CLUSTER=http://host.docker.internal:3000`
- `GITEA_REPO_OWNER=gitops`
- `INFRA_REPO_NAME=infra`
- `APP_REPO_NAME=app`
- `INFRA_BOOTSTRAP_PATH=bootstrap`

## Prerequisites

Install these binaries:

- Docker Desktop
- `kind`
- `kubectl`
- `curl`
- `argocd` CLI
- `k6` (for load testing)

## Base platform usage

From `platform/`:

```bash
make up
make status
make check
```

`make up` now also bootstraps Gitea automatically (admin user + org + `infra`/`app` repos) and locks installer mode.

Teardown:

```bash
make down
```

Full cleanup (including persisted registry/Gitea data):

```bash
make reset
```

Re-run Gitea bootstrap only:

```bash
make gitea-bootstrap
```

## Argo CD usage

Install Argo CD only:

```bash
make argo-install
```

Access Argo CD UI/API:

```bash
make argo-access
```

- `port-forward` mode (default): runs `kubectl port-forward` to `http://127.0.0.1:9080`
- `ingress` mode: exposes Argo at `http://argocd.localtest.me` (or `ARGO_INGRESS_HOST`)

Get initial admin password:

```bash
make argo-admin-password
```

Register infra repo in Argo CD:

```bash
make argo-repo-add
```

- Uses `${GITEA_REPO_HOST_FROM_CLUSTER}/${GITEA_REPO_OWNER}/${INFRA_REPO_NAME}.git`
- For private repos, set `ARGO_REPO_USERNAME` and `ARGO_REPO_PASSWORD` in `.env`

Apply minimal bootstrap Application:

```bash
make argo-bootstrap
```

One-shot flow (install + repo add + bootstrap):

```bash
make argo-up
```

Remove Argo CD:

```bash
make argo-down
```

## Kubernetes Dashboard UI

Install:

```bash
make k8s-dashboard-install
```

Get login token:

```bash
make k8s-dashboard-token
```

Access UI (keeps terminal attached):

```bash
make k8s-dashboard-access
```

Open: `https://127.0.0.1:10443`

## What `make up` does

1. Starts Docker services: local registry and Gitea.
2. Creates kind cluster using `kind/kind-config.generated.yaml` from template.
3. Configures kind containerd mirror for `${LOCAL_REGISTRY_HOST}:${LOCAL_REGISTRY_PORT}`.
4. Connects registry container to `kind` Docker network.
5. Publishes `local-registry-hosting` ConfigMap in `kube-public`.
6. Installs ingress-nginx kind provider manifest and waits for rollout.

## Argo bootstrap model

Bootstrap is a single Argo CD `Application` (`infra-bootstrap`) that points to:

- `repoURL`: `${GITEA_REPO_HOST_FROM_CLUSTER}/${GITEA_REPO_OWNER}/${INFRA_REPO_NAME}.git`
- `path`: `${INFRA_BOOTSTRAP_PATH}`
- `targetRevision`: `HEAD`

Template: `manifests/bootstrap-app.yaml.tpl`

Generated at apply time: `manifests/bootstrap-app.generated.yaml`

## Acceptance checks

Base platform checks:

```bash
make check
```

Argo CD checks:

```bash
make argo-check
```

Argo checks performed:

1. Argo pods Running:
   - Waits all pods in `${ARGO_NAMESPACE}` to become Ready.
2. UI/API reachable via chosen expose method:
   - `port-forward`: verifies `http://127.0.0.1:${ARGOCD_PORT_FORWARD_PORT}/api/version`
   - `ingress`: verifies `http://${ARGO_INGRESS_HOST}/api/version`
3. Repo add succeeds:
   - `argocd repo add` against infra repo URL and `argocd repo get` must succeed.

## Diagnostics: Argo cannot reach Gitea

If `argocd repo add` fails with DNS/connection style errors:

1. Confirm host alias works from inside cluster:
   - `kubectl run -it net-debug --rm --restart=Never --image=curlimages/curl:8.10.1 -- sh`
   - Inside pod: `curl -v ${GITEA_REPO_HOST_FROM_CLUSTER}`
2. Confirm Gitea container is up on host:
   - `docker compose -f docker-compose.yaml --env-file .env ps`
   - `curl -v http://localhost:${GITEA_HTTP_PORT}`
3. Confirm Argo repo URL value:
   - `echo ${GITEA_REPO_HOST_FROM_CLUSTER}/${GITEA_REPO_OWNER}/${INFRA_REPO_NAME}.git`
4. Check Argo repo-server logs for transport errors:
   - `kubectl -n ${ARGO_NAMESPACE} logs deploy/argocd-repo-server --tail=200`
5. If repo is private, set credentials:
   - `ARGO_REPO_USERNAME` and `ARGO_REPO_PASSWORD` in `.env`, then rerun `make argo-repo-add`

## Homepage load benchmark (k6)

Homepage-only benchmark scripts are under `platform/bench/k6`.

Run preflight:

```bash
make bench-preflight
```

Run spike scenario:

```bash
make bench-spike
```

Run ramp-and-hold scenario:

```bash
make bench-ramp
```

Outputs are written to `platform/.run/k6/` as JSON summaries.
Tune scenario parameters using `BENCH_*` values in `.env`.
