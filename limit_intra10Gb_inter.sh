#!/bin/bash
# Apply fixed intra-rack 10Gb/s and configurable inter-rack shaping.
# Idempotent and quiet by default: repeated runs won't spam RTNETLINK errors.
#
# Usage: sh limit_intra10Gb_inter.sh <0.5|1|2|5|10>

set -u

INTER_GB="${1:-}"
if [ -z "$INTER_GB" ]; then
  echo "Usage: $0 <0.5|1|2|5|10>" >&2
  exit 1
fi

case "$INTER_GB" in
  0.5) INTER_RACK_Kbps=524288 ;;
  1)   INTER_RACK_Kbps=1048576 ;;
  2)   INTER_RACK_Kbps=2097152 ;;
  5)   INTER_RACK_Kbps=5242880 ;;
  10)  INTER_RACK_Kbps=10485760 ;;
  *)
    echo "Usage: $0 <0.5|1|2|5|10>" >&2
    exit 1
    ;;
esac

INTRA_RACK_Kbps=10485760

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
  echo "Error: wondershaper not found" >&2
  exit 127
fi

TC_BIN="$(command -v tc || true)"
if [ -z "$TC_BIN" ]; then
  for p in /usr/sbin/tc /sbin/tc /usr/bin/tc; do
    if [ -x "$p" ]; then
      TC_BIN="$p"
      break
    fi
  done
fi
if [ -z "$TC_BIN" ]; then
  echo "Error: tc not found" >&2
  exit 127
fi

iface_up() {
  local iface="$1"
  ip link show "$iface" >/dev/null 2>&1 || return 1
  ip link show "$iface" 2>/dev/null | grep -q "state UP"
}

clear_iface_qdisc() {
  local iface="$1"
  "$TC_BIN" qdisc del dev "$iface" root >/dev/null 2>&1 || true
  "$TC_BIN" qdisc del dev "$iface" ingress >/dev/null 2>&1 || true
}

apply_iface_limit() {
  local iface="$1"
  local kbps="$2"
  local role="$3"
  local out

  clear_iface_qdisc "$iface"
  out="$("$WS_BIN" -a "$iface" -d "$kbps" -u "$kbps" 2>&1)" || {
    # Retry once after another cleanup in case qdisc state races.
    clear_iface_qdisc "$iface"
    out="$("$WS_BIN" -a "$iface" -d "$kbps" -u "$kbps" 2>&1)" || {
      echo "FAILED $iface role=$role rate=${kbps}Kbps: ${out}" >&2
      return 1
    }
  }

  # Output one clean status line per interface.
  echo "OK $iface role=$role rate=${kbps}Kbps"
  return 0
}

applied=0
failed=0

if iface_up enp6s0f0; then
  applied=1
  apply_iface_limit enp6s0f0 "$INTRA_RACK_Kbps" "intra" || failed=1
fi

if iface_up enp6s0f1; then
  applied=1
  apply_iface_limit enp6s0f1 "$INTER_RACK_Kbps" "inter" || failed=1
fi

if [ "$applied" -eq 0 ]; then
  echo "FAILED no active interfaces among enp6s0f0/enp6s0f1" >&2
  exit 2
fi

if [ "$failed" -ne 0 ]; then
  exit 1
fi
