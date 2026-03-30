#!/bin/bash
# 机架内 10Gb/s、机架间 1Gb/s（wondershaper，单位 Kbps）
#
# 建议用法（只测合并阶段带宽影响）：
#   - 数据放置阶段：不要执行本脚本，避免放置变慢。
#   - 出现 "start merge now? (Y/N)" 前：在另一终端执行
#       sh limit_all_intra10Gb_inter1Gb.sh
#   - 再在本机输入 Y 开始 merge。
#   - 合并结束后：sh unlimit_all_proxy.sh  解除限速。
#
# 若网卡与机架对应相反，请交换 enp6s0f0 / enp6s0f1 的带宽值。

INTRA_RACK_Kbps=10485760   # 10 Gb/s 机架内
INTER_RACK_Kbps=1048576    # 1 Gb/s 机架间

# shellcheck source=/dev/null
. "$(cd "$(dirname "$0")" && pwd)/shape_prep.sh"
shape_prep_env
shape_prep_load_modules
shape_prep_tc_resolve || { echo "Error: tc (iproute2) not found." >&2; exit 127; }

WS_BIN="$(command -v wondershaper || true)"
if [ -z "$WS_BIN" ]; then
  for p in /usr/sbin/wondershaper /sbin/wondershaper /usr/local/sbin/wondershaper /usr/bin/wondershaper; do
    if [ -x "$p" ]; then WS_BIN="$p"; break; fi
  done
fi
if [ -z "$WS_BIN" ]; then
  echo "Error: wondershaper 未找到。可: sudo apt-get install -y wondershaper  或 sh install_wondershaper.sh 装到各节点。" >&2
  exit 127
fi

# enp6s0f0: 机架内 (intra-rack)
if ip link show enp6s0f0 &> /dev/null && ip link show enp6s0f0 | grep -q 'state UP'; then
    shape_prep_clear_iface_qdisc enp6s0f0
    "$WS_BIN" -a enp6s0f0 -d "$INTRA_RACK_Kbps" -u "$INTRA_RACK_Kbps" || exit 1
    echo "enp6s0f0: $INTRA_RACK_Kbps Kbps (10Gb/s 机架内)"
fi

# enp6s0f1: 机架间 (inter-rack)
if ip link show enp6s0f1 &> /dev/null && ip link show enp6s0f1 | grep -q 'state UP'; then
    shape_prep_clear_iface_qdisc enp6s0f1
    "$WS_BIN" -a enp6s0f1 -d "$INTER_RACK_Kbps" -u "$INTER_RACK_Kbps" || exit 1
    echo "enp6s0f1: $INTER_RACK_Kbps Kbps (1Gb/s 机架间)"
fi
