#!/bin/bash

get_containers_by_tag() {
  local tag="$1"
  local lxc_dir="/etc/pve/lxc"

  if [[ ! -d "$lxc_dir" ]]; then
    log_error "LXC config directory not found: $lxc_dir"
    return 1
  fi

  for config_file in "$lxc_dir"/*.conf; do
    [[ -f "$config_file" ]] || continue

    local vmid=$(basename "$config_file" .conf)
    local tags=$(grep "^tags:" "$config_file" 2>/dev/null | cut -d: -f2)

    if [[ -n "$tags" && "$tags" == *"$tag"* ]]; then
      echo "$vmid"
    fi
  done
}

container_status() {
  local container_id="$1"
  pct status "$container_id" 2>/dev/null
}

is_container_running() {
  local container_id="$1"
  local status
  status=$(container_status "$container_id") && [[ "$status" == *"running"* ]]
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
