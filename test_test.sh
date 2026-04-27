#!/bin/bash
# intra 10Gb/s, inter <Gb/s> (wondershaper, Kbps; same as limit_1Gb.sh: 1Gb/s = 1048576 Kbps)
#
# usage: sh limit_intra10Gb_inter.sh <inter_Gb/s>
#   support: 0.5 | 1 | 2 | 5 | 10
#
# execute before merge; do not execute during placement. after merge: sh unlimit_all_proxy.sh
#
# if the network card is opposite to the rack, please swap the usage of enp6s0f0 / enp6s0f1 in the script.

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
  1)   INTER_RACK_Kbps=1048576 ;;     # 1 Gb/s (intra 10:1)
  2)   INTER_RACK_Kbps=2097152 ;;     # 2 Gb/s
  5)   INTER_RACK_Kbps=5242880 ;;     # 5 Gb/s
  10)  INTER_RACK_Kbps=10485760 ;;    # 10 Gb/s (intra same speed)
  *)
    echo "Usage: $0 <0.5|1|2|5|10>   (inter-rack Gb/s; intra-rack fixed at 10 Gb/s)" >&2
    exit 1
    ;;
esac

INTRA_RACK_Kbps=10485760   # 10 Gb/s intra (fixed)

force_clear_iface() {
  local iface="$1"
  # clear wondershaper residual, to ensure the script can be executed repeatedly.
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
    # some machines will report “Exclusivity flag on, cannot modify” due to residual qdisc, retry once.
    force_clear_iface "$iface"
    if ! "$WS_BIN" -a "$iface" -d "$rate_kbps" -u "$rate_kbps" >>/tmp/ws_apply_"$iface".log 2>&1; then
      echo "Error: failed to apply limit on $iface ($desc)" >&2
      cat /tmp/ws_apply_"$iface".log >&2
      return 1
    fi
  fi

  # verify if htb is attached.
  if ! tc qdisc show dev "$iface" 2>/dev/null | grep -q 'qdisc htb'; then
    echo "Error: $iface has no htb qdisc after shaping ($desc)." >&2
    return 1
  fi

  echo "$iface: $rate_kbps Kbps ($desc)"
  applied=1
  return 0
}

# magnific0 / Debian packaging uses -a -d -u; do not use position parameters anymore.
# enp6s0f0: intra
apply_limit_iface enp6s0f0 "$INTRA_RACK_Kbps" "intra-rack 10 Gb/s" || exit 1

# enp6s0f1: inter
apply_limit_iface enp6s0f1 "$INTER_RACK_Kbps" "inter-rack ${INTER_GB} Gb/s" || exit 1

if [ "$applied" -eq 0 ]; then
  echo "Warning: No active interface matched (enp6s0f0/enp6s0f1)." >&2
  exit 2
fi