#!/bin/bash

# SCRIPTS_DIR: the directory where this script is located
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPTS_DIR/common.sh"

# ODH_JOB_NAME: The name of the ODH Kubeflow Model Registry setup job
ODH_JOB_NAME="odh-kubeflow-model-registry-setup"

# ODH_JOB_NAMESPACE: The namespace where the ODH Kubeflow Model Registry setup job runs
ODH_JOB_NAMESPACE="odh-kubeflow-model-registry-setup"

# run_rhoai_setup: applies the ODH Kubeflow Model Registry kustomize and waits for the job
run_rhoai_setup() {
  log "Applying kustomize from $ODH_SETUP_DIR/kustomize-rhoai..."
  cd "$ODH_SETUP_DIR"
  if ! oc apply -k "./kustomize-rhoai" >/dev/null 2>&1; then
    log "Failed to apply kustomize-rhoai."
    log_fail
    exit 1
  fi
  log "Waiting for job '$ODH_JOB_NAME' to complete (this may take a while)..."
  if ! oc wait --for=condition=complete job/"$ODH_JOB_NAME" \
    -n "$ODH_JOB_NAMESPACE" --timeout=1800s >/dev/null 2>&1; then
    log "Job '$ODH_JOB_NAME' did not complete in time."
    log_fail
    exit 1
  fi
  log "Job '$ODH_JOB_NAME' completed."
}

run_rhoai_setup
