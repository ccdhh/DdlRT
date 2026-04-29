#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export LD_LIBRARY_PATH="$REPO_ROOT/project/third_party/jerasure/lib:$REPO_ROOT/project/third_party/gf-complete/lib:${LD_LIBRARY_PATH:-}"

cd "$REPO_ROOT"

# limit bandwidth
sh scripts/exp.sh 3
# run datanodes and proxies
sh scripts/exp.sh 1
# run coordinator
./project/cmake/build/run_coordinator > res/coordinator_exp5_15_2.txt &