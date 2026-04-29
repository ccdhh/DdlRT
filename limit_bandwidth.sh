#!/bin/bash
# Entry kept at repo root; implementation lives under scripts/.
ROOT="$(cd "$(dirname "$0")" && pwd)"
exec "$ROOT/scripts/limit_all_intra10Gb_inter.sh" "${1:?Usage: $0 <0.5|1|2|5|10>}"
