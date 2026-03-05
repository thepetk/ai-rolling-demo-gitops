#!/bin/bash

# Common setup sourced by all scripts.
# Requires SCRIPTS_DIR to be set before sourcing.

# GITOPS_DIR: the root of the gitops repo
GITOPS_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"

# DEPS_DIR: the directory where dependency
# shellcheck disable=SC2034
DEPS_DIR="$GITOPS_DIR/deps"

source "$SCRIPTS_DIR/logging.sh"

# ARGOCD_NAMESPACE: The namespace where ArgoCD is installed
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-openshift-gitops}"

# PAC_NAMESPACE: The namespace where OpenShift Pipelines (and Pipelines-as-Code) runs
PAC_NAMESPACE="${PAC_NAMESPACE:-openshift-pipelines}"

# LIGHTSPEED_POSTGRES_NAMESPACE: The namespace where the LightSpeed PostgreSQL instance is deployed
LIGHTSPEED_POSTGRES_NAMESPACE="${LIGHTSPEED_POSTGRES_NAMESPACE:-lightspeed-postgres}"

# RHDH_NAMESPACE: The namespace where the RHDH instance will be deployed
RHDH_NAMESPACE="${RHDH_NAMESPACE:-rolling-demo-ns}"

# ARGOCD_APP_NAME: The name of the ArgoCD application that will be deployed
ARGOCD_APP_NAME="${ARGOCD_APP_NAME:-rolling-demo}"
