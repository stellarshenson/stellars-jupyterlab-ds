---
description: Start JupyterHub platform and monitor logs in background
---

Start the JupyterHub platform using docker compose and monitor logs in a background process.

Use the Bash tool to run the following commands:

**Step 1: Start the platform**
```bash
if [ -f 'compose_override.yml' ]; then
  echo "Using compose_override.yml"
  docker compose --env-file .env -f compose.yml -f compose_override.yml up --no-recreate --no-build -d
else
  docker compose --env-file .env -f compose.yml up --no-recreate --no-build -d
fi
```

**Step 2: Monitor logs in background**
Use the Bash tool with `run_in_background: true` to follow logs:
```bash
if [ -f 'compose_override.yml' ]; then
  docker compose --env-file .env -f compose.yml -f compose_override.yml logs -f
else
  docker compose --env-file .env -f compose.yml logs -f
fi
```

After starting:
1. Inform the user that the platform is starting
2. Show the background bash session ID for log monitoring
3. Remind the user they can check logs with BashOutput tool using the session ID
4. Tell the user the platform will be accessible at `https://localhost/jupyterhub` once healthy

The user can continue working while the logs are monitored in the background.
