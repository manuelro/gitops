# Learning Checkpoints

| Checkpoint | Commands | Success looks like | If it fails |
|---|---|---|---|
| Platform baseline ready | `cd platform && make up && make status` | Gitea + registry containers up, kind nodes Ready | Start Docker Desktop, rerun `make up` |
| Ingress path works | `curl -sI http://localhost:8081/ \| head -n 1` | HTTP status line with 200/30x | Check ingress-nginx pods and ingress host rule |
| Argo installed | `cd platform && make argo-install && make argo-check` | argocd pods Running, repo add/get succeeds | Validate Argo CLI version and repo URL reachability |
| Argo UI access | `cd platform && make argo-access` | browser opens/responds at `http://127.0.0.1:9080` | Ensure port-forward is running and port free |
| K8 dashboard auth | `cd platform && make k8s-dashboard-token` | token string returned | Reinstall dashboard and recreate admin binding |
| App CI trigger | `git -C repos/app push origin main` then query Actions API | workflow run created for latest commit | Runner offline or label mismatch (`ubuntu-latest`) |
| Infra auto-promotion | `git -C repos/infra log --oneline -n 5` | bump commit appears with new tag | promotion script failed push/clone |
| Dev rollout complete | `kubectl -n demo get deploy` | client/api have available replicas | inspect pod events and image pull errors |
| Stage rollout complete | `kubectl -n demo-stage get deploy` | stage deployments healthy | verify stage overlay tag exists in registry |
| Registry contains promoted tag | `curl -fsS http://localhost:5001/v2/demo-client/tags/list` | expected tag present | rebuild and push images from app repo |
