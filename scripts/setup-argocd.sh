#!/bin/bash

# get_argocd_admin_creds: fetches argocd admin password and argocd hostname
# shellcheck disable=SC2120
get_argocd_admin_creds() {
  local namespace="${1:-openshift-gitops}"

  log "Getting Argo CD admin password and hostname from namespace '$namespace'..."
  ARGOCD_PASSWORD=$(oc get secret openshift-gitops-cluster -n "$namespace" -o jsonpath='{.data.admin\.password}' | base64 -d)
  ARGOCD_HOSTNAME=$(oc get route openshift-gitops-server -n "$namespace" -o jsonpath='{.status.ingress[0].host}')
  if [[ -z "$ARGOCD_PASSWORD" || -z "$ARGOCD_HOSTNAME" ]]; then
    log "Failed to retrieve Argo CD credentials. Exiting."
    return 1
  fi
  export ARGOCD_PASSWORD
  export ARGOCD_HOSTNAME
  log "Retrieved Argo CD admin credentials."
}

# enable_argocd_admin_apiKey: Enables argoCD admin apiKey capability
enable_argocd_admin_apiKey() {
  local namespace="$1"
  local argocd_name="$2"
  local temp_file="argocd-patched.yaml"

  log "Exporting Argo CD CR from namespace '$namespace'..."
  if ! kubectl get argocd "$argocd_name" -n "$namespace" -o yaml > argocd.yaml 2>/dev/null; then
    log "Failed to fetch Argo CD CR. Exiting."
    log_fail
    exit 1
  fi
  if grep -q "accounts.admin: apiKey" argocd.yaml; then
    log "Argo CD CR already contains 'accounts.admin: apiKey'. Skipping patch."
  else
    log "Patching Argo CD CR to enable 'accounts.admin: apiKey'..."
    yq eval '.spec.extraConfig."accounts.admin" = "apiKey"' argocd.yaml > "$temp_file"
    log "Applying updated Argo CD CR..."
    if ! kubectl apply -f "$temp_file" -n "$namespace" >/dev/null 2>&1; then
      log "Failed to apply patched CR. Exiting."
      rm -f "$temp_file"
      log_fail
      exit 1
    fi
    log "Cleaning up temporary files..."
    rm -f "$temp_file"
    log "Patch applied successfully."
  fi
  rm -f argocd.yaml
}

# generate_argocd_api_token: generates argoCD api key after logging in to the argocd server
generate_argocd_api_token() {
  local namespace="${1:-openshift-gitops}"

  log "Retrieving Argo CD creds..."
  get_argocd_admin_creds
  if ! argocd login "$ARGOCD_HOSTNAME" \
    --username admin \
    --password "$ARGOCD_PASSWORD" \
    --insecure \
    --skip-test-tls \
    --grpc-web >/dev/null 2>&1; then
    log "Login failed."
    log_fail
    return 1
  fi
  log "Generating API token for admin account..."
  ARGOCD_API_TOKEN=$(argocd account generate-token --account admin)
  if [[ -z "$ARGOCD_API_TOKEN" ]]; then
    log "Failed to generate API token."
    return 1
  fi
  export ARGOCD_API_TOKEN
  log "ARGOCD_API_TOKEN exported for this session."
}

log "Setting up ArgoCD apiKey..."
enable_argocd_admin_apiKey "$ARGOCD_NAMESPACE" "$ARGOCD_NAMESPACE"

log "Generating the ARGOCD_API_TOKEN..."
generate_argocd_api_token "$ARGOCD_NAMESPACE"
