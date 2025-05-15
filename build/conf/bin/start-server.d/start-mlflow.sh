#!/bin/bash

# key variables
MLFLOW_BACKEND_STORE_URI=${MLFLOW_BACKEND_STORE_URI:-sqlite:///mlflow/mlflow.db}
MLFLOW_ARTIFACT_ROOT=${MLFLOW_ARTIFACT_ROOT:-/mlflow/artifacts}
MLFLOW_PORT=${MLFLOW_SERVER_PORT:-5000}
MLFLOW_HOST=${MLFLOW_SERVER_HOST:-0.0.0.0}
MLFLOW_TRACKING_URI=${MLFLOW_TRACKING_URI:-http://localhost:5000}
CONDA_DEFAULT_ENV=base

COMMAND=$(cat <<EOF
mlflow server \
  --backend-store-uri $MLFLOW_BACKEND_STORE_URI \
  --default-artifact-root $MLFLOW_ARTIFACT_ROOT \
  --host $MLFLOW_HOST \
  --port $MLFLOW_PORT
EOF
)

conda run -n $CONDA_DEFAULT_ENV "$COMMAND"


# EOF

