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

LOG_FILE="/var/log/proxmox-container-update.log"
LOG_DIR=$(dirname "$LOG_FILE")

_log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local log_entry="[$timestamp] [$level] $message"

  if [[ "$level" == "ERROR" ]] || [[ "$level" == "WARN" ]]; then
    echo "$log_entry" >&2
  else
    echo "$log_entry"
  fi

  if [[ -w "$LOG_DIR" ]] || [[ ! -e "$LOG_FILE" && -w "$LOG_DIR" ]]; then
    echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || true
  fi
}

log_info() {
  _log "INFO" "$@"
}

log_error() {
  _log "ERROR" "$@"
}

log_warn() {
  _log "WARN" "$@"
}
