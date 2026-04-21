#!/bin/bash
# 在所有 proxy 节点分发执行单机限速脚本（仅入口脚本使用 pdsh）
# Usage: sh limit_all_intra10Gb_inter.sh <0.5|1|2|5|10>

INTER_GB="${1:-}"
if [ -z "$INTER_GB" ]; then
  echo "Usage: $0 <0.5|1|2|5|10>" >&2
  exit 1
fi

HOSTS_FILE="proxy_hosts"
USER="root"
REMOTE_COMMAND="cd /users/qiliang/UniLRC && LIMIT_AUTO_IFUP=1 LIMIT_FALLBACK_10NET=1 bash limit_intra10Gb_inter.sh $INTER_GB"
PARALLEL=5

echo "Applying intra 10 Gb/s + inter ${INTER_GB} Gb/s on all proxy nodes..."
sudo pdsh -S -R ssh -w ^"$HOSTS_FILE" -l "$USER" -f "$PARALLEL" "$REMOTE_COMMAND"
pdsh_rc=$?

if [ "$pdsh_rc" -eq 0 ]; then
	echo "Done (all nodes ok)."
else
	echo "Done with errors: pdsh exit $pdsh_rc (see messages above)."
  exit "$pdsh_rc"
fi
