#!/bin/bash
# deprecated independent implementation; please use limit_intra10Gb_inter.sh.
# kept this file for compatibility with old documents / call `sh test_test.sh <Gb>`，logic is the same as limit_intra10Gb_inter.sh.
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/limit_intra10Gb_inter.sh" "${1:?Usage: $0 <0.5|1|2|5|10>}"