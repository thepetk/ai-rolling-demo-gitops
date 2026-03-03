#!/bin/bash

# SCRIPTS_DIR: the directory where this script is located
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPTS_DIR/common.sh"

source "$SCRIPTS_DIR/private-env"

# ff RHDH_NAMESPACE is overridden via env var, recompute URL vars
# that private-env hardcodes using the default namespace.
if [[ -n "${RHDH_NAMESPACE}" ]]; then
  RHDH_BASE_URL="https://rolling-demo-backstage-${RHDH_NAMESPACE}.${RHDH_CLUSTER_ROUTER_BASE}"
  RHDH_CALLBACK_URL="${RHDH_BASE_URL}/api/auth/oidc/handler/frame"
  export RHDH_BASE_URL RHDH_CALLBACK_URL
fi

# check_tools: verifies that all required CLI tools are installed
check_tools() {
  local missing=()
  local tools=("oc" "kubectl" "yq" "argocd" "cosign")

  for tool in "${tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      log "'$tool' is not installed or not in PATH."
      missing+=("$tool")
    else
      log "'$tool' is installed."
    fi
  done
  if (( ${#missing[@]} )); then
    log "Missing required tools: ${missing[*]}"
    log_fail
    exit 1
  fi
}

log "Setting Up Rolling Demo Environment..."
log "Checking if all required tools are installed..."
check_tools

# Validate required env vars
required_vars=(
  GITOPS_REPO_URL
  GITOPS_TARGET_REVISION
  RHDH_CLUSTER_ROUTER_BASE
  ODH_SETUP_DIR
  GITHUB_ORG
  GITHUB_APP_APP_ID
  GITHUB_APP_CLIENT_ID
  GITHUB_APP_CLIENT_SECRET
  GITHUB_APP_WEBHOOK_URL
  GITHUB_APP_WEBHOOK_SECRET
  GITHUB_APP_PRIVATE_KEY
  ARGOCD_USER
  BACKEND_SECRET
  RHDH_CALLBACK_URL
  POSTGRESQL_POSTGRES_PASSWORD
  POSTGRESQL_USER_PASSWORD
  QUAY_DOCKERCONFIGJSON
  KEYCLOAK_METADATA_URL
  KEYCLOAK_CLIENT_ID
  KEYCLOAK_REALM
  KEYCLOAK_BASE_URL
  KEYCLOAK_LOGIN_REALM
  KEYCLOAK_CLIENT_SECRET
  OLLAMA_URL
  OLLAMA_TOKEN
  VLLM_URL
  VLLM_API_KEY
  VALIDATION_PROVIDER
  VALIDATION_MODEL_NAME
)
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    log "Error: $var is not set. Exiting..."
    log_fail
    exit 1
  fi
done

# skip operators and RHOAI installation if that's the case
[[ "${SKIP_INSTALL_DEPS}" == "true" ]] && log "SKIP_INSTALL_DEPS=true — skipping operator/instance installation." || bash "$SCRIPTS_DIR/install-operators.sh"
[[ "${SKIP_RHOAI_SETUP}" == "true" ]]  && log "SKIP_RHOAI_SETUP=true — skipping ODH Kubeflow Model Registry setup." || bash "$SCRIPTS_DIR/setup-rhoai.sh"

# source other setup scripts to create namespaces, service accounts, secrets, and ArgoCD setup
source "$SCRIPTS_DIR/setup-argocd.sh"
source "$SCRIPTS_DIR/setup-namespaces.sh"
source "$SCRIPTS_DIR/setup-sa-tokens.sh"
source "$SCRIPTS_DIR/setup-secrets.sh"

# finally apply ArgoCD applications to deploy the demo components
bash "$SCRIPTS_DIR/setup-pipelines.sh"
bash "$SCRIPTS_DIR/apply-argocd-application.sh"

log "Rolling Demo Setup Completed Successfully!"
