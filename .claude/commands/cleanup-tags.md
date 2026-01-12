---
description: Clean up Docker Hub tags for stellars-jupyterlab-ds
allowed-tools: Bash, AskUserQuestion
---

# Clean Up Docker Hub Tags

This command helps remove old or unwanted tags from Docker Hub for the `stellars/stellars-jupyterlab-ds` repository.

## Current Tags on Docker Hub

!`curl -s "https://hub.docker.com/v2/repositories/stellars/stellars-jupyterlab-ds/tags?page_size=100" | jq -r '.results[].name' | sort -V`

## Instructions

1. Show the user the current tags listed above
2. Ask the user which tags to delete using AskUserQuestion with options like:
   - Delete all tags below version X.Y (e.g., "Delete all 3.4.x and lower")
   - Delete specific version range (e.g., "Delete 3.3.x only")
   - Delete tags matching a pattern
   - Custom selection
3. After user confirms, use Docker Hub API to delete the selected tags:
   - Get credentials via: `echo "https://index.docker.io/v1/" | docker-credential-desktop.exe get`
   - Get JWT token from Docker Hub login API
   - Delete each tag via DELETE request to `https://hub.docker.com/v2/repositories/stellars/stellars-jupyterlab-ds/tags/{tag}/`
4. Report results showing which tags were deleted successfully

## Authentication

Use Docker Desktop credential helper to get username and PAT:
```bash
CREDS=$(echo "https://index.docker.io/v1/" | docker-credential-desktop.exe get)
USERNAME=$(echo "$CREDS" | jq -r '.Username')
PASSWORD=$(echo "$CREDS" | jq -r '.Secret')
```

Then get JWT token:
```bash
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST \
  -d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}" \
  https://hub.docker.com/v2/users/login/ | jq -r .token)
```

## Deletion

Delete tag via API:
```bash
curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  "https://hub.docker.com/v2/repositories/stellars/stellars-jupyterlab-ds/tags/{TAG}/"
```

HTTP 204 = success, other codes = failure.
