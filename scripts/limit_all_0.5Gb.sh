#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOSTS_FILE="$REPO_ROOT/proxy_hosts"
REMOTE_DIR="${REMOTE_DIR:-DdlRT}"

USER="root"

REMOTE_COMMAND="cd $REMOTE_DIR && bash scripts/limit_0.5Gb.sh"

PARALLEL=5

echo "Running command on all nodes..."
sudo pdsh -R ssh -w ^"$HOSTS_FILE" -l "$USER" -f "$PARALLEL" "$REMOTE_COMMAND"

if [ $? -eq 0 ]; then
	echo "Command executed successfully on all nodes."
else
	echo "Failed to execute command on some nodes."
fi
