#!/bin/bash

get_containers_by_tag() {
  local tag="$1"
  pct list --format json 2>/dev/null | \
    jq -r ".[] | select((.tags // \"\") | contains(\"$tag\")) | .vmid" 2>/dev/null
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
