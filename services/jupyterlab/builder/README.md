# Builder Scripts

Build-time scripts consumed exclusively by the `builder` stage of `Dockerfile.jupyterlab`. These scripts produce artifacts (wheels, Docker CLI plugin binaries) that are exported to `${EXPORT_DIR}` in the builder stage and pulled into the runtime stage via a single `COPY --from=builder ${EXPORT_DIR} ${EXPORT_DIR}`.

## Constraint

These scripts are **not** present in the runtime image. The Dockerfile copies this folder into the builder stage only:

```dockerfile
COPY --chmod=755 ./builder/ /opt/builder/
```

There is no corresponding `COPY --from=builder /opt/builder ...` in the target stage and there must not be one. If a runtime concern needs similar logic, it belongs under `conf/` instead.

## Scripts

- `install-docker-plugins.sh` - Downloads bundled Docker CLI plugins from upstream GitHub release binaries (currently `docker-mcp`, `docker-buildx`, `docker-compose`). Drops binaries into `${EXPORT_DIR}/docker-cli-plugins/`. Plugin list with pinned versions is hardcoded in the script
- `build-llama-cpp-python.sh` - Builds the `llama-cpp-python` wheel with CUDA support and exports it to `${EXPORT_DIR}`

## Adding or updating a Docker CLI plugin

Edit the `PLUGINS` array in `install-docker-plugins.sh`. Each entry is a `|`-separated string `name|download-url|kind`:

- `kind=raw` - the downloaded file is the plugin binary itself (compose, buildx)
- `kind=tarball:<inner>` - the download is a gzipped tarball; extract and use the file named `<inner>` (mcp)

Versions are pinned for reproducibility. To bump, replace the URL with the new release tag. Example bump for compose:

```bash
"compose|https://github.com/docker/compose/releases/download/v5.2.0/docker-compose-linux-x86_64|raw"
```

Pre-built binaries are preferred over source builds: faster image builds, no Go toolchain dependency, and reproducible across rebuilds.

## Conventions

- All scripts use `set -euo pipefail`
- Scripts read `BUILD_DIR` and `EXPORT_DIR` as positional arguments (Dockerfile `ARG` values are not exported as env to `RUN` invocations)
- No state outside `$BUILD_DIR` (work) and `$EXPORT_DIR` (artifacts)
