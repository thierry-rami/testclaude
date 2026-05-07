# Proxmox LXC Container Update Manager

Updates Debian/Ubuntu packages on all LXC containers tagged with `laplateforme` in Proxmox.

## Requirements

- Proxmox server
- Root access (required for `pct` commands)
- Bash 4+
- `jq` for JSON parsing

## Usage

```bash
chmod +x src/main.sh src/utils.sh
./src/main.sh
```

## How it works

1. Queries Proxmox for all containers tagged `laplateforme`
2. For each running container:
   - Runs `apt update`
   - Checks for available updates
   - Runs `apt full-upgrade` if updates exist
3. Logs all operations and skips stopped/non-existent containers
