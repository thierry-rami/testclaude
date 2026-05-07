#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/utils.sh"

PROXMOX_TAG="laplateforme"

main() {
  log_info "Fetching containers with tag '$PROXMOX_TAG' from Proxmox..."

  local containers
  containers=$(get_containers_by_tag "$PROXMOX_TAG") || {
    log_error "Failed to fetch containers from Proxmox"
    exit 1
  }

  if [[ -z "$containers" ]]; then
    log_warn "No containers found with tag '$PROXMOX_TAG'"
    exit 0
  fi

  process_containers "$containers"
}

process_containers() {
  local containers="$1"

  while IFS= read -r container_id; do
    [[ -z "$container_id" ]] && continue

    log_info "Processing container: $container_id"
    update_container "$container_id"
  done <<< "$containers"
}

update_container() {
  local container_id="$1"

  if ! container_exists "$container_id"; then
    log_warn "Container '$container_id' does not exist"
    return 1
  fi

  if ! is_container_running "$container_id"; then
    log_warn "Container '$container_id' is not running"
    return 1
  fi

  log_info "Running apt update on container $container_id..."
  pct exec "$container_id" -- apt update || {
    log_error "apt update failed on container $container_id"
    return 1
  }

  log_info "Checking for updates on container $container_id..."
  local updates=$(pct exec "$container_id" -- apt list --upgradable 2>/dev/null | grep -c "^" || echo "0")

  if [[ $updates -gt 0 ]]; then
    log_info "Found $updates packages to upgrade on container $container_id"
    log_info "Running apt full-upgrade on container $container_id..."
    pct exec "$container_id" -- DEBIAN_FRONTEND=noninteractive apt full-upgrade -y || {
      log_error "apt full-upgrade failed on container $container_id"
      return 1
    }
    log_info "Upgrade completed for container $container_id"
  else
    log_info "No upgrades available for container $container_id"
  fi
}

main "$@"
