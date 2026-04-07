#!/bin/bash
# 机架内固定 10Gb/s，机架间带宽可配（wondershaper，单位 Kbps；与现有 limit_1Gb.sh 一致：1Gb/s = 1048576 Kbps）
#
# 用法: sh limit_intra10Gb_inter.sh <机架间_Gb/s>
#   支持: 0.5 | 1 | 2 | 5 | 10
#
# 合并前再执行；放置阶段勿执行。合并后: sh unlimit_all_proxy.sh
#
# 若网卡与机架对应相反，请交换脚本里 enp6s0f0 / enp6s0f1 的用途。

INTER_GB="${1:-}"

set -u

# shellcheck source=/dev/null
. "$(cd "$(dirname "$0")" && pwd)/shape_prep.sh"
shape_prep_env
shape_prep_load_modules
shape_prep_tc_resolve || { echo "Error: tc (iproute2) not found." >&2; exit 127; }

WS_BIN="$(command -v wondershaper || true)"
if [ -z "$WS_BIN" ]; then
  for p in /usr/sbin/wondershaper /sbin/wondershaper /usr/local/sbin/wondershaper /usr/bin/wondershaper; do
    if [ -x "$p" ]; then
      WS_BIN="$p"
      break
    fi
  done
fi
if [ -z "$WS_BIN" ]; then
  echo "Error: wondershaper if not found。Debian/Ubuntu can: sudo apt-get install -y wondershaper" >&2
  echo "  if use install_wondershaper.sh to install from source code; if only pdsh to send to all nodes，can not install on node0." >&2
  exit 127
fi

applied=0

case "$INTER_GB" in
  0.5) INTER_RACK_Kbps=524288 ;;      # 0.5 Gb/s
  1)   INTER_RACK_Kbps=1048576 ;;     # 1 Gb/s (与机架内 10:1)
  2)   INTER_RACK_Kbps=2097152 ;;     # 2 Gb/s
  5)   INTER_RACK_Kbps=5242880 ;;     # 5 Gb/s
  10)  INTER_RACK_Kbps=10485760 ;;    # 10 Gb/s（与机架内同速）
  *)
    echo "Usage: $0 <0.5|1|2|5|10>   (inter-rack Gb/s; intra-rack fixed at 10 Gb/s)" >&2
    exit 1
    ;;
esac

INTRA_RACK_Kbps=10485760   # 10 Gb/s 机架内（固定）

force_clear_iface() {
  local iface="$1"
  # 清理 wondershaper 残留，保证脚本可重复执行。
  "$WS_BIN" -c -a "$iface" >/dev/null 2>&1 || true
  tc qdisc del dev "$iface" root >/dev/null 2>&1 || true
  tc qdisc del dev "$iface" ingress >/dev/null 2>&1 || true
}

apply_limit_iface() {
  local iface="$1"
  local rate_kbps="$2"
  local desc="$3"

  if ! ip link show "$iface" >/dev/null 2>&1; then
    return 0
  fi
  if ! ip link show "$iface" | grep -q 'state UP'; then
    return 0
  fi

  force_clear_iface "$iface"
  if ! "$WS_BIN" -a "$iface" -d "$rate_kbps" -u "$rate_kbps" >/tmp/ws_apply_"$iface".log 2>&1; then
    # 部分机器第一次会因残留 qdisc 报 “Exclusivity flag on, cannot modify”，重试一次。
    force_clear_iface "$iface"
    if ! "$WS_BIN" -a "$iface" -d "$rate_kbps" -u "$rate_kbps" >>/tmp/ws_apply_"$iface".log 2>&1; then
      echo "Error: failed to apply limit on $iface ($desc)" >&2
      cat /tmp/ws_apply_"$iface".log >&2
      return 1
    fi
  fi

  # 验证是否已挂上 htb。
  if ! tc qdisc show dev "$iface" 2>/dev/null | grep -q 'qdisc htb'; then
    echo "Error: $iface has no htb qdisc after shaping ($desc)." >&2
    return 1
  fi

  echo "$iface: $rate_kbps Kbps ($desc)"
  applied=1
  return 0
}

# magnific0 / Debian 包装均使用 -a -d -u；勿再用位置参数
# enp6s0f0: 机架内
apply_limit_iface enp6s0f0 "$INTRA_RACK_Kbps" "intra-rack 10 Gb/s" || exit 1

# enp6s0f1: 机架间
apply_limit_iface enp6s0f1 "$INTER_RACK_Kbps" "inter-rack ${INTER_GB} Gb/s" || exit 1

if [ "$applied" -eq 0 ]; then
  echo "Warning: No active interface matched (enp6s0f0/enp6s0f1)." >&2
  exit 2
fi