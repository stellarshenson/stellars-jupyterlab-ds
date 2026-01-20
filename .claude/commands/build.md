---
description: Build JupyterHub Docker image with verbose output
---

Build the JupyterHub Docker image using docker compose with verbose logging (--progress=plain).

Use the Bash tool to run the following command from the project root:

```bash
export DOCKER_DEFAULT_PLATFORM=linux/amd64 && \
export COMPOSE_BAKE=true && \
docker compose -f compose.yml build --progress=plain
```

This will:
- Build the `stellars/stellars-jupyterhub-ds:latest` image
- Show detailed build logs with --progress=plain
- Use linux/amd64 platform explicitly
- Build from the compose.yml file

After the build completes, inform the user of the result and provide the image name and tag.
