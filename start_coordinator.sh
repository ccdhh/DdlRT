#!/bin/bash
set -euo pipefail

USER="root"
REMOTE_DIR="${REMOTE_DIR:-DdlRT}"

REMOTE_COMMAND="cd $REMOTE_DIR && bash scripts/run_coordinator.sh"

PARALLEL=5

echo "Running command on all nodes..."
pdsh -S -R ssh -w 10.10.1.2 -l "$USER" -f "$PARALLEL" "$REMOTE_COMMAND"
pdsh_rc=$?

if [ "$pdsh_rc" -eq 0 ]; then
	echo "Command executed successfully on all nodes."
else
	echo "Failed to execute command on some nodes (pdsh exit $pdsh_rc)."
	exit "$pdsh_rc"
fi
