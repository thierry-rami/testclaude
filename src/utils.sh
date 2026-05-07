#!/bin/bash

# Utility functions for Proxmox LXC container management

get_containers_by_tag() {
  local tag="$1"

  # Get containers with the specified tag from Proxmox
  # Uses 'pct list' and filters by tags
  local containers
  containers=$(pct list --format json 2>/dev/null | \
    jq -r ".[] | select(.tags | contains(\"$tag\")) | .vmid" 2>/dev/null)

  if [[ -z "$containers" ]]; then
    return 1
  fi

  echo "$containers"
}

container_exists() {
  local container_id="$1"
  pct status "$container_id" >/dev/null 2>&1 && return 0 || return 1
}

is_container_running() {
  local container_id="$1"
  local status=$(pct status "$container_id" 2>/dev/null)
  [[ "$status" == *"running"* ]] && return 0 || return 1
}

log_info() {
  echo "[INFO] $*"
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_warn() {
  echo "[WARN] $*" >&2
}
