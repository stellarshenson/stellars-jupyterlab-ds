#!/bin/bash
# ----------------------------------------------------------------------------------------
# MLflow Tracking Server Launch Script
#
# Launches MLflow Tracking Server for experiment tracking, model versioning,
# and artifact storage. Runs inside the base Conda environment.
#
# Server is accessed via jupyter-server-proxy at /proxy/5000/ or /mlflow/.
# CORS is enabled for all origins via MLFLOW_SERVER_CORS_ALLOWED_ORIGINS
# to support cross-origin requests from JupyterHub proxy.
#
# Gunicorn runs from /tmp to keep control socket out of workspace.
# Logs are written to /var/log/mlflow.log.
#
# ENVIRONMENT VARIABLES:
#   ENABLE_SERVICE_MLFLOW            - Set to 1 to enable (required)
#   MLFLOW_DATA                      - Data directory (default: ~/.cache/mlflow)
#   MLFLOW_BACKEND_STORE_URI         - Backend metadata storage URI (default: sqlite:///<data>/mlflow.sqlite3)
#   MLFLOW_ARTIFACT_ROOT             - Artifact storage directory (default: <data>/artifacts)
#   MLFLOW_SERVER_PORT               - Port to bind (default: 5000)
#   MLFLOW_HOST                      - IP address to bind (default: 0.0.0.0)
#   MLFLOW_TRACKING_URI              - Tracking URI for clients (default: http://localhost:5000)
#   MLFLOW_WORKERS                   - Number of Gunicorn workers (default: 1)
#   MLFLOW_SERVER_ALLOWED_HOSTS      - Allowed Host headers for DNS rebinding protection (default: *)
#   MLFLOW_SERVER_CORS_ALLOWED_ORIGINS - Allowed CORS origins (default: *)
#   FORWARDED_ALLOW_IPS              - Gunicorn proxy IPs to trust (default: *)
#
# REQUIREMENTS:
#   - Conda must be installed and available in PATH
#   - MLflow must be installed in the base Conda environment
# ----------------------------------------------------------------------------------------

# check if enabled
if [[ ${ENABLE_SERVICE_MLFLOW} != 1 ]]; then
    exit 0
fi

# ensure log file exists
touch /var/log/mlflow.log 2>/dev/null || true

# configure MLflow environment
MLFLOW_DATA=${MLFLOW_DATA:-$HOME/.cache/mlflow} && mkdir -p ${MLFLOW_DATA}
MLFLOW_BACKEND_STORE_URI=${MLFLOW_BACKEND_STORE_URI:-sqlite:///${MLFLOW_DATA}/mlflow.sqlite3}
MLFLOW_ARTIFACT_ROOT=${MLFLOW_ARTIFACT_ROOT:-${MLFLOW_DATA}/artifacts}
MLFLOW_WORKERS=${MLFLOW_WORKERS:-1}
MLFLOW_PORT=${MLFLOW_SERVER_PORT:-5000}
MLFLOW_HOST=${MLFLOW_HOST:-0.0.0.0}
MLFLOW_TRACKING_URI=${MLFLOW_TRACKING_URI:-http://localhost:5000}
FORWARDED_ALLOW_IPS=${FORWARDED_ALLOW_IPS:-*}
MLFLOW_SERVER_ALLOWED_HOSTS=${MLFLOW_SERVER_ALLOWED_HOSTS:-*}
MLFLOW_SERVER_CORS_ALLOWED_ORIGINS=${MLFLOW_SERVER_CORS_ALLOWED_ORIGINS:-*}

# launch MLflow server
COMMAND=$(cat <<EOF
export FORWARDED_ALLOW_IPS='$FORWARDED_ALLOW_IPS'
export MLFLOW_SERVER_ALLOWED_HOSTS='$MLFLOW_SERVER_ALLOWED_HOSTS'
export MLFLOW_SERVER_CORS_ALLOWED_ORIGINS='$MLFLOW_SERVER_CORS_ALLOWED_ORIGINS'
echo "Launching MLflow tracking server on $MLFLOW_HOST:$MLFLOW_PORT"
mlflow server \\
  --backend-store-uri $MLFLOW_BACKEND_STORE_URI \\
  --default-artifact-root $MLFLOW_ARTIFACT_ROOT \\
  --workers $MLFLOW_WORKERS \\
  --host $MLFLOW_HOST \\
  --port $MLFLOW_PORT \\
  --serve-artifacts \\
  --gunicorn-opts "--access-logfile=-"
EOF
)

# use conda to execute (cd /tmp to keep gunicorn.ctl out of workspace)
cd /tmp && conda run -n base --no-capture-output bash -c "$COMMAND" >> /var/log/mlflow.log 2>&1 &

# EOF
