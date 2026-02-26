# ADR-0001: Workspace Shape and Repository Boundaries

**Status:** Accepted  
**Date:** 2026-02-25

## Decision
Use one local workspace with three clear modules:
- `platform/` for runtime/bootstrap automation
- `repos/app` as standalone app source repo
- `repos/infra` as standalone desired-state repo

## Context
The workflow requires app code, infra manifests, and platform automation to evolve independently while still being runnable on one machine.

## Options considered
| Option | Pros | Cons |
|---|---|---|
| Single monorepo for everything | Simple root view | Blurs runtime vs desired-state ownership |
| Separate top-level repos only | Strong isolation | Harder local onboarding |
| Workspace with module boundaries (chosen) | Fast local setup + clear ownership lines | Requires docs to explain boundaries |

## Decision drivers
- Keep local onboarding under 15 minutes.
- Preserve real GitOps separation between app and infra.
- Keep platform scripts independent from app release cadence.

## Consequences
Pros:
- Clear handoff between build artifact and deploy intent.
- Easier troubleshooting by layer.

Cons:
- Multiple Git repos to manage.

Mitigations:
- Root docs and code map point to exact commands and paths.

## Operational notes
- Run platform lifecycle from `platform/`.
- Commit app and infra changes in their own repos.

## Validation
```bash
cd .
ls -1
```
Expected outcome shape:
- shows `platform`, `repos`, `docs`
- `repos` contains `app` and `infra`, each with its own `.git`
