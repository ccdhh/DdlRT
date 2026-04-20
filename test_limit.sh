#!/bin/bash
# Apply intra 10Gb/s + configurable inter-rack rate on all proxy nodes.
# Usage: sh test_limit.sh <0.5|1|2|5|10>

INTER_GB="${1:-}"
if [ -z "$INTER_GB" ]; then
  echo "Usage: $0 <0.5|1|2|5|10>" >&2
  exit 1
fi

HOSTS_FILE="proxy_hosts"
USER="root"
REMOTE_COMMAND="cd /users/qiliang/UniLRC && sh limit_intra10Gb_inter.sh $INTER_GB"
PARALLEL=5

echo "Applying intra 10 Gb/s + inter ${INTER_GB} Gb/s on all proxy nodes..."
sudo pdsh -R ssh -w ^"$HOSTS_FILE" -l "$USER" -f "$PARALLEL" "$REMOTE_COMMAND"

if [ $? -eq 0 ]; then
	echo "Done."
else
	echo "Some nodes may have failed."
fi