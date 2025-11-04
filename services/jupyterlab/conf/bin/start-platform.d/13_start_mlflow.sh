#!/bin/bash
# ----------------------------------------------------------------------------------------
# MLflow Tracking Server Launch Script
#
# This script launches an MLflow Tracking Server, used to manage the end-to-end
# machine learning lifecycle including experiment tracking, model versioning,
# and artifact storage.
#
# It starts the server with configurable environment variables and runs it inside
# a specified Conda environment.
#
# USAGE:
#   ./start_mlflow.sh
#
# ENVIRONMENT VARIABLES:
#   MLFLOW_BACKEND_STORE_URI - URI for backend metadata storage (default: sqlite:///mnt/mlflow/mlflow.db)
#   MLFLOW_ARTIFACT_ROOT     - Directory to store uploaded artifacts (default: /mnt/mlflow/artifacts)
#   MLFLOW_SERVER_PORT       - Port to bind the server to (default: 5000)
#   MLFLOW_SERVER_HOST       - IP address to bind (default: 0.0.0.0)
#   MLFLOW_TRACKING_URI      - Tracking URI for MLflow clients (default: http://localhost:5000)
#
# REQUIREMENTS:
#   - Conda must be installed and available in PATH
#   - MLflow must be installed in the 'base' Conda environment
# ----------------------------------------------------------------------------------------

# check if enabled
if [[ ${ENABLE_SERVICE_MLFLOW} != 1 ]]; then
    exit 0
fi

# key variables
MLFLOW_DATA=${MLFLOW_DATA:-$HOME/.cache/mlflow} && mkdir -p ${MLFLOW_DATA}
MLFLOW_BACKEND_STORE_URI=${MLFLOW_BACKEND_STORE_URI:-sqlite:///${MLFLOW_DATA}/mlflow.sqlite3}
MLFLOW_ARTIFACT_ROOT=${MLFLOW_ARTIFACT_ROOT:-${MLFLOW_DATA}/artifacts}
MLFLOW_WORKERS=${MLFLOW_WORKERS:-1}
MLFLOW_PORT=${MLFLOW_SERVER_PORT:-5000}
MLFLOW_HOST=${MLFLOW_SERVER_HOST:-0.0.0.0}
MLFLOW_TRACKING_URI=${MLFLOW_TRACKING_URI:-http://localhost:5000}

# command to execute with Gunicorn configuration
COMMAND=$(cat <<EOF
echo "Launching MLFlow models artefacts and experiments management server"
export GUNICORN_CMD_ARGS="--forwarded-allow-ips='*' --access-logfile -"
mlflow server \
  --backend-store-uri $MLFLOW_BACKEND_STORE_URI \
  --default-artifact-root $MLFLOW_ARTIFACT_ROOT \
  --workers $MLFLOW_WORKERS \
  --host $MLFLOW_HOST \
  --port $MLFLOW_PORT \
  --serve-artifacts
EOF
)

# use conda to execute with environment variables passed through
conda run -n base --no-capture-output bash -c "$COMMAND" &

# EOF

