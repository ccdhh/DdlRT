#!/bin/bash
# 机架内固定 10Gb/s，机架间带宽可配（wondershaper，单位 Kbps；与现有 limit_1Gb.sh 一致：1Gb/s = 1048576 Kbps）
#
# 用法: bash limit_intra10Gb_inter.sh <机架间_Gb/s>   或  ./limit_intra10Gb_inter.sh …
# （勿依赖 `sh`：若 sh 为 bash 的 POSIX 模式，不支持 < <(...) 类写法；本脚本已改为兼容 sh。）
#   支持: 0.5 | 1 | 2 | 5 | 10
#
# 合并前再执行；放置阶段勿执行。合并后: sh unlimit_all_proxy.sh
#
# 若机架内/间与 f0/f1 对应相反，请改 try_pair 中的 apply_intra/apply_inter 分配。
# 若仍 exit 2：无可用 enp*s0f*、或 f1 上无 10.x、或链路无载波；请检查接线/ip addr；bond 等非 enp* 命名需另配。

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

# magnific0 / Debian 包装均使用 -a -d -u；勿再用位置参数
# 约定: *s0f0 = 机架内, *s0f1 = 机架间（与 enp6 文档一致）。若相反请改本脚本或交换端口接线/路由。
# LIMIT_AUTO_IFUP=1（默认）：先对存在的口执行 ip link set up。
# LIMIT_FALLBACK_10NET=1（默认）：无双口可用时，对带 10.x 地址的 enp*f1 仅做机架间限速。

iface_can_shape() {
  local dev="$1"
  local line
  line=$(ip link show "$dev" 2>/dev/null | head -1) || return 1
  case "$line" in
    *"state UP"*) return 0 ;;
    *LOWER_UP*) return 0 ;;
  esac
  return 1
}

try_bring_up_pair() {
  local a="$1" b="$2"
  [ "${LIMIT_AUTO_IFUP:-1}" != "0" ] || return 0
  ip link show "$a" &>/dev/null && ip link set "$a" up 2>/dev/null || true
  ip link show "$b" &>/dev/null && ip link set "$b" up 2>/dev/null || true
  sleep 0.05 2>/dev/null || true
}

ws_clear_iface() {
  local dev="$1"
  "$WS_BIN" -c -a "$dev" 2>/dev/null || true
}

apply_intra() {
  local dev="$1"
  ws_clear_iface "$dev"
  shape_prep_clear_iface_qdisc "$dev"
  "$WS_BIN" -a "$dev" -d "$INTRA_RACK_Kbps" -u "$INTRA_RACK_Kbps" || return 1
  echo "$dev: $INTRA_RACK_Kbps Kbps (10 Gb/s intra-rack)"
}

apply_inter() {
  local dev="$1"
  ws_clear_iface "$dev"
  shape_prep_clear_iface_qdisc "$dev"
  "$WS_BIN" -a "$dev" -d "$INTER_RACK_Kbps" -u "$INTER_RACK_Kbps" || return 1
  echo "$dev: $INTER_RACK_Kbps Kbps (inter-rack ${INTER_GB} Gb/s)"
}

# 对一对 (intra_dev, inter_dev) 在可用口上应用；任一口成功则返回 0
try_pair() {
  local intra_dev="$1" inter_dev="$2"
  local ok=0
  try_bring_up_pair "$intra_dev" "$inter_dev"
  if iface_can_shape "$intra_dev"; then
    apply_intra "$intra_dev" || return 1
    ok=1
  fi
  if iface_can_shape "$inter_dev"; then
    apply_inter "$inter_dev" || return 1
    ok=1
  fi
  [ "$ok" -eq 1 ]
}

# 1) 常见固定名  2) 自动探测 enp*s0f0 / 同组 f1（覆盖混用 enp4/enp6 或 PCI 槽位不同）
try_all_pairs() {
  local intra_dev inter_dev
  for intra_dev in enp6s0f0 enp4s0f0; do
    inter_dev="${intra_dev%f0}f1"
    ip link show "$inter_dev" &> /dev/null || continue
    if try_pair "$intra_dev" "$inter_dev"; then
      return 0
    fi
  done

  while IFS= read -r intra_dev; do
    [ -n "$intra_dev" ] || continue
    inter_dev="${intra_dev%f0}f1"
    ip link show "$inter_dev" &> /dev/null || continue
    if try_pair "$intra_dev" "$inter_dev"; then
      return 0
    fi
  done <<EOF
$(ip -o link show | awk -F': ' '
  $2 !~ /^lo/ {
    gsub(/@.*/, "", $2)
    d = $2
    if ($0 !~ / state UP / && $0 !~ /LOWER_UP/) next
    if (d ~ /^enp[0-9]+s[0-9]+f0$/) print d
    else if (d ~ /^enp[0-9]+s[0-9]+f1$/) { sub(/f1$/, "f0", d); print d }
  }' | sort -uV)
EOF

  return 1
}

# 无双口 f0/f1 同时可用时：选已配置 10.x 的 enp*f1 只做机架间限速（与多数节点仅 enp4s0f1 UP 一致）
try_fallback_10net_inter() {
  local d f0
  [ "${LIMIT_FALLBACK_10NET:-1}" = "1" ] || return 1
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    case "$d" in
      enp[0-9]*s[0-9]*f1) ;;
      *) continue ;;
    esac
    ip -4 -o addr show dev "$d" 2>/dev/null | grep -qE 'inet 10\.' || continue
    f0="${d%f1}f0"
    try_bring_up_pair "$f0" "$d"
    iface_can_shape "$d" || continue
    echo "Note: inter-rack only on $d (fallback: 10.x on f1, no usable f0/f1 pair)." >&2
    apply_inter "$d" && return 0
  done <<EOF
$(ip -o link show | awk -F': ' '
  $2 !~ /^lo/ {
    gsub(/@.*/, "", $2)
    if ($2 ~ /^enp[0-9]+s[0-9]+f1$/) print $2
  }' | sort -uV)
EOF
  return 1
}

try_all_pairs || try_fallback_10net_inter || {
  echo "Warning: No interface could be shaped (tried pairs, LOWER_UP, ifup, and 10.x f1 fallback)." >&2
  exit 2
}
