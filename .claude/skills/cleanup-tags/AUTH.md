# Authentication

## Docker Desktop Credential Helper

Get username and PAT from Docker Desktop:

```bash
CREDS=$(echo "https://index.docker.io/v1/" | docker-credential-desktop.exe get)
USERNAME=$(echo "$CREDS" | jq -r '.Username')
PASSWORD=$(echo "$CREDS" | jq -r '.Secret')
```

## JWT Token

Exchange credentials for Docker Hub JWT token:

```bash
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST \
  -d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}" \
  https://hub.docker.com/v2/users/login/ | jq -r .token)
```

The token is used in the Authorization header for subsequent API calls.
