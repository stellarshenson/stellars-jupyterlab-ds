#!/bin/bash

# Input URL and project/service details
URL="$1"
PROJECT_NAME="stellars-jupyterlab-ds"
SERVICE_NAME="jupyterlab"

# Check if the URL is provided
if [ -z "$URL" ]; then
  echo "Usage: $0 <URL>"
  exit 1
fi

# Step 1: Parse the port from the URL
PORT=$(echo "$URL" | grep -oP 'redirect_uri=http%3A%2F%2F127\.0\.0\.1%3A\K[0-9]+')

if [ -z "$PORT" ]; then
  echo "Error: Could not extract port from URL."
  exit 1
fi

echo "Parsed port from URL: $PORT"

# Cleanup function to kill processes and stop Docker socat
cleanup() {
  echo "Cleaning up..."
  # Kill the local socat process
  if [ -n "$LOCAL_SOCAT_PID" ]; then
    echo "Terminating local socat process (PID: $LOCAL_SOCAT_PID)"
    kill "$LOCAL_SOCAT_PID" 2>/dev/null
  fi

  # Stop the Docker socat process
  echo "Stopping socat inside Docker container..."
  docker-compose -p "$PROJECT_NAME" exec "$SERVICE_NAME" bash -c "pkill -f 'socat TCP-LISTEN:3030'"
}

# Trap EXIT signal to ensure cleanup
trap cleanup EXIT

# Step 2: Run socat in the Docker container
DOCKER_COMMAND="socat TCP-LISTEN:3030,fork,reuseaddr TCP:127.0.0.1:${PORT}"
echo "Executing socat in Docker Compose service $SERVICE_NAME to forward from port 3030 to $PORT"
docker-compose -p "$PROJECT_NAME" exec -d "$SERVICE_NAME" bash -c "$DOCKER_COMMAND"

if [ $? -ne 0 ]; then
  echo "Error: Failed to execute socat in the Docker Compose service."
  exit 1
fi

# Step 3: Run local socat to listen on the parsed port and forward to port 3030
echo "Starting local socat to listen on port $PORT and forward to local port 3030"
socat TCP-LISTEN:$PORT,fork,reuseaddr TCP:127.0.0.0:3030

# EOF

