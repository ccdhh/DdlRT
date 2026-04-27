#!/bin/bash
# intra 10Gb/s, inter 1Gb/s (wondershaper, Kbps)
#
# recommended usage (only test the bandwidth impact during merge):
#   - during placement: do not execute this script, to avoid slower placement.
#   - before "start merge now? (Y/N)": execute in another terminal
#       sh limit_intra10Gb_inter1Gb.sh
#   - then input Y in this machine to start merge.
#   - after merge: sh unlimit_all_proxy.sh to unlimit the bandwidth.
#
# if the network card is opposite to the rack, please swap the usage of enp6s0f0 / enp6s0f1 in the script.

INTRA_RACK_Kbps=10485760   # 10 Gb/s intra
INTER_RACK_Kbps=1048576    # 1 Gb/s inter

# enp6s0f0: intra
if ip link show enp6s0f0 &> /dev/null && ip link show enp6s0f0 | grep -q 'state UP'; then
    wondershaper -a enp6s0f0 -d $INTRA_RACK_Kbps -u $INTRA_RACK_Kbps
    echo "enp6s0f0: $INTRA_RACK_Kbps Kbps (10Gb/s intra)"
fi

# enp6s0f1: inter
if ip link show enp6s0f1 &> /dev/null && ip link show enp6s0f1 | grep -q 'state UP'; then
    wondershaper -a enp6s0f1 -d $INTER_RACK_Kbps -u $INTER_RACK_Kbps
    echo "enp6s0f1: $INTER_RACK_Kbps Kbps (1Gb/s inter)"
fi
