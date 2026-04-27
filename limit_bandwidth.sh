#!/bin/bash
# 在所有 proxy 节点上：机架内 10Gb/s + 指定机架间带宽（Gb/s）
# 用法: sh limit_all_intra10Gb_inter.sh <0.5|1|2|5|10>
#
# 五次实验示例（每次合并前执行一条，合并后 unlimit_all_proxy.sh）:
#   sh limit_all_intra10Gb_inter.sh 0.5
#   sh limit_all_intra10Gb_inter.sh 1
#   sh limit_all_intra10Gb_inter.sh 2
#   sh limit_all_intra10Gb_inter.sh 5
#   sh limit_all_intra10Gb_inter.sh 10

INTER_GB="${1:-}"
if [ -z "$INTER_GB" ]; then
  echo "Usage: $0 <0.5|1|2|5|10>" >&2
  exit 1
fi

HOSTS_FILE="proxy_hosts"
USER="root"
# 远端必须用 bash 执行 limit_intra10Gb_inter.sh；LIMIT_* 见该脚本（自动 up、10.x f1 回退、tc 多次清理）。
REMOTE_COMMAND="cd /users/qiliang/UniLRC && LIMIT_AUTO_IFUP=1 LIMIT_FALLBACK_10NET=1 bash limit_intra10Gb_inter.sh $INTER_GB"
PARALLEL=5

echo "Applying intra 10 Gb/s + inter ${INTER_GB} Gb/s on all proxy nodes..."
# -S：任一节点非 0 退出时 pdsh 整体非 0，便于发现失败节点
sudo pdsh -S -R ssh -w ^$HOSTS_FILE -l $USER -f $PARALLEL "$REMOTE_COMMAND"
pdsh_rc=$?

if [ "$pdsh_rc" -eq 0 ]; then
	echo "Done (all nodes ok)."
else
	echo "Done with errors: pdsh exit $pdsh_rc (see messages above)."
	exit "$pdsh_rc"
fi