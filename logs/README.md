# Build and Job Logs

Logs from background builds and long-running jobs in this deployment.

- `rebuild.log` - output of `make rebuild` (target-stage Docker rebuild, written when DEBUG=1)
- `rebuild-bugfix.log` - output of the `make rebuild` that baked the 2026-07-07 bug-fix batch (quoting, healthcheck, token handling, service gating) into the image
