# Homepage Benchmark Module

This module defines homepage-only load tests for the `demo-client` ingress endpoint.

## Prerequisites

- `k6` installed (`brew install k6`)
- Platform running (`make up`)
- Demo app deployed and reachable at `http://localhost:8081/`

## Scenarios

- `homepage-spike.js`: burst traffic to `40k` users (configurable).
- `homepage-ramp-hold.js`: ramp -> hold -> rampdown hat-shape profile.

## Commands

From `platform/`:

```bash
make bench-preflight
make bench-spike
make bench-ramp
```

Summary files are written to:

`platform/.run/k6/*.json`

## Environment knobs

Set in `.env`:

- `BENCH_BASE_URL` (default `http://localhost:8081`)
- `BENCH_SPIKE_USERS` (default `40000`)
- `BENCH_SPIKE_RAMP_SECONDS` (default `120`)
- `BENCH_SPIKE_HOLD_SECONDS` (default `600`)
- `BENCH_RAMP_USERS` (default `40000`)
- `BENCH_RAMP_SECONDS` (default `1800`)
- `BENCH_HOLD_SECONDS` (default `1800`)
- `BENCH_RAMPDOWN_SECONDS` (default `900`)
- `BENCH_REFRESH_RATE` (default `0.10`)
- `BENCH_SESSION_SECONDS` (default `300`)
