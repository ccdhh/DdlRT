#!/bin/bash
# unlimit the bandwidth on all proxy nodes (used with limit_all_intra10Gb_inter1Gb.sh)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOSTS_FILE="$REPO_ROOT/proxy_hosts"
REMOTE_DIR="${REMOTE_DIR:-DdlRT}"
USER="root"
REMOTE_COMMAND="cd $REMOTE_DIR && bash scripts/unlimit_both_interfaces.sh"
PARALLEL=5

echo "Clearing bandwidth limits on all proxy nodes..."
sudo pdsh -R ssh -w ^"$HOSTS_FILE" -l "$USER" -f "$PARALLEL" "$REMOTE_COMMAND"

if [ $? -eq 0 ]; then
	echo "Done."
else
	echo "Some nodes may have failed."
fi
