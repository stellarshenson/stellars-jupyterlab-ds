---
description: Clean up Docker Hub tags for stellars-jupyterlab-ds
allowed-tools: Bash, AskUserQuestion
---

# Clean Up Docker Hub Tags

Manage and remove old or unwanted tags from Docker Hub for the `stellars/stellars-jupyterlab-ds` repository.

## Current Tags

!`curl -s "https://hub.docker.com/v2/repositories/stellars/stellars-jupyterlab-ds/tags?page_size=100" | jq -r '.results[].name' | sort -V`

## Workflow

1. Show the user the current tags listed above
2. Ask which tags to delete using AskUserQuestion with options:
   - Delete all tags below version X.Y (e.g., "Delete all 3.4.x and lower")
   - Delete specific version range (e.g., "Delete 3.3.x only")
   - Delete tags matching a pattern
   - Custom selection
3. Authenticate using Docker credential helper (see AUTH.md)
4. Delete selected tags via Docker Hub API (see API.md)
5. Report results showing which tags were deleted successfully
