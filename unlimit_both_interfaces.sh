#!/bin/bash
# unlimit the bandwidth on enp6s0f0 and enp6s0f1 (used with limit_intra10Gb_inter1Gb.sh)

if ip link show enp6s0f0 &> /dev/null && ip link show enp6s0f0 | grep -q 'state UP'; then
    wondershaper -c -a enp6s0f0
    echo "cleared: enp6s0f0"
fi
if ip link show enp6s0f1 &> /dev/null && ip link show enp6s0f1 | grep -q 'state UP'; then
    wondershaper -c -a enp6s0f1
    echo "cleared: enp6s0f1"
fi
