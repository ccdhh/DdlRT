#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
HOSTS_FILE="$BASE_DIR/proxy_hosts"
REMOTE_DIR="${REMOTE_DIR:-DdlRT}"

USER="root"

REMOTE_COMMAND="cd $REMOTE_DIR && bash scripts/run_proxy_datanode.sh"

PARALLEL=50

echo "Running command on all nodes..."
sudo pdsh -R ssh -w ^"$HOSTS_FILE" -l "$USER" -f "$PARALLEL" "$REMOTE_COMMAND"

if [ $? -eq 0 ]; then
	echo "Command executed successfully on all nodes."
else
	echo "Failed to execute command on some nodes."
fi
