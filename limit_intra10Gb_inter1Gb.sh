#!/bin/bash
# intra 10Gb/s, inter 1Gb/s (wondershaper, unit Kbps)
# usage: bash limit_intra10Gb_inter1Gb.sh
# if the network card is opposite, please swap the bandwidth values of enp6s0f0 / enp6s0f1.

INTRA_RACK_Kbps=10485760   # 10 Gb/s intra-rack
INTER_RACK_Kbps=1048576    # 1 Gb/s inter-rack

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
  echo "Error: wondershaper not found. Can: sudo apt-get install -y wondershaper   or sh install_wondershaper.sh install to all nodes." >&2
  exit 127
fi

# enp6s0f0: intra-rack (intra-rack)
if ip link show enp6s0f0 &> /dev/null && ip link show enp6s0f0 | grep -q 'state UP'; then
    shape_prep_clear_iface_qdisc enp6s0f0
    "$WS_BIN" -a enp6s0f0 -d "$INTRA_RACK_Kbps" -u "$INTRA_RACK_Kbps" || exit 1
    echo "enp6s0f0: $INTRA_RACK_Kbps Kbps (10Gb/s intra-rack)"
fi

# enp6s0f1: inter-rack (inter-rack)
if ip link show enp6s0f1 &> /dev/null && ip link show enp6s0f1 | grep -q 'state UP'; then
    shape_prep_clear_iface_qdisc enp6s0f1
    "$WS_BIN" -a enp6s0f1 -d "$INTER_RACK_Kbps" -u "$INTER_RACK_Kbps" || exit 1
    echo "enp6s0f1: $INTER_RACK_Kbps Kbps (1Gb/s inter-rack)"
fi
