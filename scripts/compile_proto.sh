#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROTO_DIR="$REPO_ROOT/project/src/proto"
PROTOC="$REPO_ROOT/project/third_party/grpc/bin/protoc"
GRPC_PLUGIN="$REPO_ROOT/project/third_party/grpc/bin/grpc_cpp_plugin"

cd "$PROTO_DIR"
"$PROTOC" --proto_path=. --grpc_out=. --plugin=protoc-gen-grpc="$GRPC_PLUGIN" coordinator.proto
"$PROTOC" --proto_path=. --cpp_out=. coordinator.proto
"$PROTOC" --proto_path=. --grpc_out=. --plugin=protoc-gen-grpc="$GRPC_PLUGIN" proxy.proto
"$PROTOC" --proto_path=. --cpp_out=. proxy.proto
"$PROTOC" --proto_path=. --grpc_out=. --plugin=protoc-gen-grpc="$GRPC_PLUGIN" datanode.proto
"$PROTOC" --proto_path=. --cpp_out=. datanode.proto