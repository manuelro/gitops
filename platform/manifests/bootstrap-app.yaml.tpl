apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infra-bootstrap
  namespace: __ARGO_NAMESPACE__
spec:
  project: __ARGO_PROJECT__
  source:
    repoURL: __INFRA_REPO_URL__
    targetRevision: HEAD
    path: __INFRA_BOOTSTRAP_PATH__
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
