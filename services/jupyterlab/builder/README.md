# Builder Scripts

Build-time scripts consumed exclusively by the `builder` stage of `Dockerfile.jupyterlab`. These scripts produce artifacts (wheels, Docker CLI plugin binaries) that are exported to `${EXPORT_DIR}` in the builder stage and pulled into the runtime stage via a single `COPY --from=builder ${EXPORT_DIR} ${EXPORT_DIR}`.

## Constraint

These scripts are **not** present in the runtime image. The Dockerfile copies this folder into the builder stage only:

```dockerfile
COPY --chmod=755 ./builder/ /opt/builder/
```

There is no corresponding `COPY --from=builder /opt/builder ...` in the target stage and there must not be one. If a runtime concern needs similar logic, it belongs under `conf/` instead.

## Scripts

- `build-docker-plugins.sh` - Builds all bundled Docker CLI plugins from upstream Go source (currently `docker-mcp` and `docker-buildx`). Static builds via `CGO_ENABLED=0`, output binaries land in `${EXPORT_DIR}/docker-cli-plugins/`. Plugin list is hardcoded in the script
- `build-llama-cpp-python.sh` - Builds the `llama-cpp-python` wheel with CUDA support and exports it to `${EXPORT_DIR}`

## Adding a new Docker CLI plugin

Edit the `PLUGINS` array in `build-docker-plugins.sh`. Each entry is a `|`-separated string `name|repo-url|entrypoint|extra-ldflags`. Example for `docker-compose`:

```bash
"compose|https://github.com/docker/compose.git|./cmd|-X github.com/docker/compose/v2/internal.Version=v2.x.y"
```

The fourth field is optional — leave empty if no extra ldflags are needed. The compose plugin embeds its version via `-X github.com/docker/compose/v2/internal.Version=<tag>`; without it, `docker compose version` reports `unknown`.

## Conventions

- All scripts use `set -euo pipefail`
- Scripts read `BUILD_DIR` and `EXPORT_DIR` as positional arguments (Dockerfile `ARG` values are not exported as env to `RUN` invocations)
- No state outside `$BUILD_DIR` (work) and `$EXPORT_DIR` (artifacts)
