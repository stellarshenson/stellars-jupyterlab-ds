# Docker Hub API Reference

## Repository

- **Owner:** stellars
- **Repository:** stellars-jupyterlab-ds
- **Base URL:** `https://hub.docker.com/v2/repositories/stellars/stellars-jupyterlab-ds`

## List Tags

```bash
curl -s "https://hub.docker.com/v2/repositories/stellars/stellars-jupyterlab-ds/tags?page_size=100" \
  | jq -r '.results[].name'
```

## Delete Tag

```bash
curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  "https://hub.docker.com/v2/repositories/stellars/stellars-jupyterlab-ds/tags/{TAG}/"
```

## Response Codes

| Code | Meaning |
|------|---------|
| 204 | Success - tag deleted |
| 401 | Unauthorized - token invalid |
| 404 | Tag not found |
| 403 | Forbidden - insufficient permissions |
