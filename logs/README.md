# Build and Job Logs

Logs from background builds and long-running jobs in this deployment.

- `rebuild.log` - output of `make rebuild` (target-stage Docker rebuild, written when DEBUG=1)
- `rebuild-bugfix.log` - output of the `make rebuild` that baked the 2026-07-07 bug-fix batch (quoting, healthcheck, token handling, service gating) into the image
- `rebuild-sweep.log` / `rebuild-sweep2.log` - rebuilds for the 2026-07-07 solution-wide sweep (SIGTERM/exec fix, loopback binds, env-store unification, self-test, Run on Start)
- `rebuild-usability.log` - rebuild for the usability round (PATH bake, pip-cache prevention)
- `rebuild-round5.log` - rebuild baking the 2026-07-08 re-confirm fixes (protected env names, conda-env install sentinels, mlflow URI derivation) and the UX round (Settings menu, menu state restore, applet polish)
- `rebuild-round6.log` - rebuild baking the round-6 fixes (Default Shell allowlist, Settings freeze fix, installer name preservation) and the pulseaudio restart fix + voice self-test
- `container-test-round6.log` - 66-check container verification of the round-6 image (incl. voice restart survival)
- `rebuild-round7.log` - rebuild baking the round-7 fixes (env-store non-UTF-8 wipe guard, port-knob typo guard, esc Clear-filter label, hint contrast)
- `rebuild-round8.log` - rebuild baking the round-8 fixes (start.bat one-line .env writer, self-test detail width, backspace guard, delete-cursor neighbour, hook launch logging)
- `rebuild-round9.log` - rebuild baking the round-9 fixes (condarc channel-freeze fix, anchored persistence guards, hint-once launch wrapper, single mlflow URI derivation, CONDA_CMD unification)
- `rebuild-round10.log` - final rebuild + installers baking the round-10 polish (voice FAIL log pointer, call-time script-group resolution, CONDA_CMD in the menu's conda branch)
- `container-test-final.log` - final 68-check container verification (voice restart survival, condarc purity, round-6..10 bake probes)
