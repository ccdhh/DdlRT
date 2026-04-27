#!/bin/bash
# compatible entry: forward to the unified script limit_all_intra10Gb_inter.sh

DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/limit_all_intra10Gb_inter.sh" "${1:?Usage: $0 <0.5|1|2|5|10>}"