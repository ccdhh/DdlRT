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

# enp6s0f0: intra
if ip link show enp6s0f0 &> /dev/null && ip link show enp6s0f0 | grep -q 'state UP'; then
    wondershaper -a enp6s0f0 -d $INTRA_RACK_Kbps -u $INTRA_RACK_Kbps
    echo "enp6s0f0: $INTRA_RACK_Kbps Kbps (10 Gb/s intra)"
fi

# enp6s0f1: inter
if ip link show enp6s0f1 &> /dev/null && ip link show enp6s0f1 | grep -q 'state UP'; then
    wondershaper -a enp6s0f1 -d $INTER_RACK_Kbps -u $INTER_RACK_Kbps
    echo "enp6s0f1: $INTER_RACK_Kbps Kbps (inter ${INTER_GB} Gb/s)"
fi
