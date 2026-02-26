SHELL := /bin/bash

.PHONY: up down status reset check gitea-bootstrap argo-install argo-access argo-admin-password argo-repo-add argo-bootstrap argo-up argo-down argo-check k8s-dashboard-install k8s-dashboard-token k8s-dashboard-access k8s-dashboard-uninstall bench-preflight bench-spike bench-ramp

up:
	./scripts/up.sh

down:
	./scripts/down.sh

status:
	./scripts/status.sh

reset:
	./scripts/reset.sh

check:
	./scripts/checks.sh

gitea-bootstrap:
	./scripts/gitea-bootstrap.sh

argo-install:
	./scripts/install-argocd.sh

argo-access:
	./scripts/argocd-access.sh

argo-admin-password:
	./scripts/argocd-admin-password.sh

argo-repo-add:
	./scripts/argocd-repo-add.sh

argo-bootstrap:
	./scripts/argocd-bootstrap.sh

argo-up:
	./scripts/argocd-up.sh

argo-down:
	./scripts/argocd-down.sh

argo-check:
	./scripts/argocd-check.sh

k8s-dashboard-install:
	./scripts/install-k8s-dashboard.sh

k8s-dashboard-token:
	./scripts/k8s-dashboard-token.sh

k8s-dashboard-access:
	./scripts/k8s-dashboard-access.sh

k8s-dashboard-uninstall:
	./scripts/uninstall-k8s-dashboard.sh

bench-preflight:
	./scripts/bench-preflight.sh

bench-spike:
	./scripts/bench-spike.sh

bench-ramp:
	./scripts/bench-ramp.sh
