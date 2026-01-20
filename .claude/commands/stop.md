---
description: Stop JupyterHub platform and clean up orphaned containers
---

Stop the JupyterHub platform and clean up dangling images, containers, networks, and volumes.

Use the Bash tool to run:
```bash
make clean
```

This will:
1. Stop and remove all containers defined in compose.yml
2. Remove orphaned containers not defined in the compose file
3. Prune dangling Docker images
4. Prune unused Docker networks
5. Clean up resources to free disk space

After completion, inform the user that:
- The platform has been stopped
- Orphaned containers have been removed
- Dangling images and networks have been pruned
- The environment is clean and ready for a fresh start

If any background log monitoring sessions are still running, remind the user they can kill them using the KillShell tool.
