#!/bin/bash
# single node script: set the bandwidth on the current node
# - intra-rack interface: 10 Gb/s
# - inter-rack interface: <INTER_GB> Gb/s
# Usage: bash limit_intra10Gb_inter.sh <0.5|1|2|5|10>

set -u

INTER_GB="${1:-}"
if [ -z "$INTER_GB" ]; then
  echo "Usage: $0 <0.5|1|2|5|10>" >&2
  exit 1
fi

if ! awk "BEGIN{exit !($INTER_GB > 0)}"; then
  echo "Error: invalid rate '$INTER_GB'" >&2
  exit 1
fi

INTRA_RACK_KBPS=10485760
INTER_RACK_KBPS="$(awk "BEGIN{printf \"%d\", $INTER_GB*1024*1024}")"
AUTO_IFUP="${LIMIT_AUTO_IFUP:-0}"
FALLBACK_10NET="${LIMIT_FALLBACK_10NET:-0}"

WS_BIN="$(command -v wondershaper || true)"
if [ -z "$WS_BIN" ]; then
  for p in /usr/sbin/wondershaper /sbin/wondershaper /usr/bin/wondershaper; do
    if [ -x "$p" ]; then
      WS_BIN="$p"
      break
    fi
  done
fi
if [ -z "$WS_BIN" ]; then
  echo "Error: wondershaper not found." >&2
  exit 127
fi

bring_up_if_needed() {
  local iface="$1"
  if [ "$AUTO_IFUP" = "1" ]; then
    ip link set dev "$iface" up >/dev/null 2>&1 || true
  fi
}

apply_limit() {
  local iface="$1"
  local role="$2"
  local kbps="$3"
  local label="$4"

  if ! ip link show "$iface" >/dev/null 2>&1; then
    return 1
  fi

  bring_up_if_needed "$iface"
  tc qdisc del dev "$iface" root >/dev/null 2>&1 || true
  tc qdisc del dev "$iface" ingress >/dev/null 2>&1 || true

  if ! "$WS_BIN" -a "$iface" -d "$kbps" -u "$kbps" >/dev/null 2>&1; then
    echo "ERR iface=$iface role=$role set failed" >&2
    return 2
  fi

  local qdisc_state
  qdisc_state="$(tc qdisc show dev "$iface" 2>/dev/null)"
  case "$qdisc_state" in
    *"htb "*)
      echo "OK iface=$iface role=$role rate=${kbps}Kbps (${label})"
      return 0
      ;;
    *)
      echo "ERR iface=$iface role=$role verify failed: ${qdisc_state}" >&2
      return 3
      ;;
  esac
}

pick_fallback_ifaces() {
  local inter=""
  local intra=""
  while read -r line; do
    local iface="${line%% *}"
    local addr="${line##* }"
    case "$addr" in
      10.*)
        if [ -z "$inter" ] && [[ "$iface" == *f1 ]]; then
          inter="$iface"
        fi
        if [ -z "$intra" ] && [[ "$iface" == *f0 ]]; then
          intra="$iface"
        fi
        if [ -z "$inter" ]; then
          inter="$iface"
        fi
        if [ -z "$intra" ]; then
          intra="$iface"
        fi
        ;;
    esac
  done < <(ip -o -4 addr show up scope global | awk '{print $2, $4}')
  echo "$intra $inter"
}

INTRA_IF="enp6s0f0"
INTER_IF="enp6s0f1"
if [ "$FALLBACK_10NET" = "1" ]; then
  if ! ip link show "$INTRA_IF" >/dev/null 2>&1 || ! ip link show "$INTER_IF" >/dev/null 2>&1; then
    read -r fb_intra fb_inter < <(pick_fallback_ifaces)
    if [ -n "${fb_intra:-}" ]; then
      INTRA_IF="$fb_intra"
    fi
    if [ -n "${fb_inter:-}" ]; then
      INTER_IF="$fb_inter"
    fi
  fi
fi

failed=0
applied=0

if apply_limit "$INTRA_IF" "intra" "$INTRA_RACK_KBPS" "10Gb/s"; then
  applied=1
else
  failed=1
fi

if apply_limit "$INTER_IF" "inter" "$INTER_RACK_KBPS" "${INTER_GB}Gb/s"; then
  applied=1
else
  failed=1
fi

if [ "$applied" -eq 0 ]; then
  echo "ERR no interface applied (tried intra=$INTRA_IF inter=$INTER_IF)" >&2
  exit 1
fi

exit "$failed"