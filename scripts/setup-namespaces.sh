#!/bin/bash

# create_project: creates a project in openshift
create_project() {
  local namespace="$1"

  if oc get project "$namespace" >/dev/null 2>&1; then
    log "Project '$namespace' already exists."
  else
    log "Creating project '$namespace'..."
    if oc new-project "$namespace" >/dev/null 2>&1; then
      log "Project '$namespace' created successfully."
    else
      log "Failed to create project '$namespace'. Exiting."
      log_fail
      exit 1
    fi
  fi
}

# add_argocd_label: labels a given openshift project for argocd
add_argocd_label() {
  local namespace="$1"
  local argocd_namespace="${2:-openshift-gitops}"

  if ! oc label namespace "$namespace" "argocd.argoproj.io/managed-by=$argocd_namespace" --overwrite >/dev/null 2>&1; then
    log "Failed to label namespace '$namespace'. Exiting."
    log_fail
    return 1
  fi
  log "Project '$namespace' labeled successfully."
}


log "Creating new project for $RHDH_NAMESPACE..."
create_project "$RHDH_NAMESPACE"

log "Creating new project for $LIGHTSPEED_POSTGRES_NAMESPACE..."
create_project "$LIGHTSPEED_POSTGRES_NAMESPACE"

log "Labeling $LIGHTSPEED_POSTGRES_NAMESPACE for ArgoCD management..."
add_argocd_label "$LIGHTSPEED_POSTGRES_NAMESPACE"
