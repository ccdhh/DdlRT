#!/bin/bash
# 已弃用独立实现；请使用 limit_intra10Gb_inter.sh。
# 保留本文件仅为兼容旧文档/习惯调用 `sh test_test.sh <Gb>`，逻辑与 limit_intra10Gb_inter.sh 完全一致。

DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/limit_intra10Gb_inter.sh" "${1:?Usage: $0 <0.5|1|2|5|10>}"
