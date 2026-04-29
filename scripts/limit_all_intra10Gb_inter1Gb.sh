#!/bin/bash
# set the bandwidth on all proxy nodes: intra 10Gb/s, inter 1Gb/s
# recommended to execute before merge; do not execute during placement, to avoid slowing down the write.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOSTS_FILE="$REPO_ROOT/proxy_hosts"
REMOTE_DIR="${REMOTE_DIR:-DdlRT}"
USER="root"
REMOTE_COMMAND="cd $REMOTE_DIR && bash scripts/limit_intra10Gb_inter1Gb.sh"
PARALLEL=5

echo "Running bandwidth limit on all nodes (intra 10Gb, inter 1Gb)..."
sudo pdsh -R ssh -w ^"$HOSTS_FILE" -l "$USER" -f "$PARALLEL" "$REMOTE_COMMAND"

if [ $? -eq 0 ]; then
	echo "Command executed successfully on all nodes."
else
	echo "Failed to execute command on some nodes."
fi
