# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Bash script that automatically updates Debian/Ubuntu packages on Proxmox LXC containers tagged `laplateforme`. Discovers tagged containers via Proxmox CLI and runs `apt update` + `apt full-upgrade` on each running container.

**Requirements:** Proxmox server, root/sudo access, Bash 4+, jq

## Common Commands

```bash
# Make scripts executable
chmod +x src/main.sh src/utils.sh

# Run updates on all tagged containers
./src/main.sh

# Validate Bash syntax
bash -n src/main.sh src/utils.sh

# Test Proxmox connectivity (check if pct works)
pct list --format json | jq .
```

## Architecture

**Two-module design:**

**`src/main.sh`** — Orchestration & entry point
- `main()` — Fetches containers by tag, exits if none found
- `process_containers()` — Loops through each container ID, calls `update_container()`
- `update_container()` — Performs apt operations on a single container

**`src/utils.sh`** — Proxmox operations & helpers
- `get_containers_by_tag(tag)` — Queries Proxmox with `pct list --format json`, filters by tag using jq, returns container IDs
- `container_exists(id)` — Validates container ID exists (via `pct status`)
- `is_container_running(id)` — Checks if container is running (parses `pct status` output)
- `log_info/error/warn()` — Prefixed logging to stdout/stderr

**Execution flow:**
1. Script queries Proxmox for containers with tag `laplateforme`
2. For each container ID:
   - Verify container exists and is running (skip if not)
   - Execute `apt update` inside container
   - Parse `apt list --upgradable` to check for available updates
   - If updates exist: execute `apt full-upgrade -y` with `DEBIAN_FRONTEND=noninteractive`
3. Log all operations; failures don't halt subsequent containers

## Important Implementation Notes

- **Proxmox tool:** Use `pct` (Proxmox Container Toolkit), not raw `lxc-*` commands for compatibility
- **Running check required:** Never run apt on stopped containers; the script validates running state
- **jq filtering:** Tag filtering uses `select(.tags | contains("laplateforme"))` — tags field must exist and be a string or array
- **Non-interactive apt:** Uses `DEBIAN_FRONTEND=noninteractive` to suppress prompts during full-upgrade
- **Error resilience:** Each container failure is logged; script continues processing remaining containers
- **Return codes:** Script exits 1 if no tagged containers found, otherwise exits 0 (even if some updates failed)
