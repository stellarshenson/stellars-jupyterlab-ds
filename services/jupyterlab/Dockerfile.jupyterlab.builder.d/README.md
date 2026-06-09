# Builder Installer Scripts

Run in the `builder` stage to produce artifacts exported via `COPY --from=builder`. Not shipped in the image.

- `install-docker-plugins.sh` - downloads pinned Docker CLI plugins (`docker-mcp`, `docker-buildx`, `docker-compose`) into `${EXPORT_DIR}/docker-cli-plugins/`
- `build-llama-cpp-python.sh` - builds the CUDA `llama-cpp-python` wheel into `${EXPORT_DIR}`

Scripts take `BUILD_DIR` and `EXPORT_DIR` as positional args, use `set -euo pipefail`.
