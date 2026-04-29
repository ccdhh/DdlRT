#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
CRT_DIR="$REPO_ROOT"

cd "$CRT_DIR"

ASIO_INSTALL_DIR="$CRT_DIR/project/third_party/asio"
GRPC_INSTALL_DIR="$CRT_DIR/project/third_party/grpc"
GF_INSTALL_DIR="$CRT_DIR/project/third_party/gf-complete"
JERASURE_INSTALL_DIR="$CRT_DIR/project/third_party/jerasure"

ASIO_DIR="$CRT_DIR/third_party/asio-1.24.0"
GRPC_DIR="$CRT_DIR/third_party/grpc"
GF_DIR="$CRT_DIR/third_party/gf-complete"
JERASURE_DIR="$CRT_DIR/third_party/jerasure"

echo "=== Installing asio ==="
mkdir -p "$ASIO_INSTALL_DIR"
rm -rf "$ASIO_INSTALL_DIR"/* || true

cd "$CRT_DIR/third_party"
rm -rf asio-1.24.0

tar -xvzf asio.tar.gz
cd "$ASIO_DIR"
./configure --prefix="$ASIO_INSTALL_DIR"
make -j6
make install

echo "=== Installing grpc ==="
mkdir -p "$GRPC_INSTALL_DIR"
rm -rf "$GRPC_INSTALL_DIR"/* || true

cd "$CRT_DIR/third_party"
rm -rf grpc

tar -xvzf grpc.tar.gz
cd "$GRPC_DIR"
mkdir -p cmake/build
cd cmake/build
cmake -DgRPC_INSTALL=ON \
    -DgRPC_BUILD_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX="$GRPC_INSTALL_DIR" \
    ../..
make -j6
make install

echo "=== Installing gf-complete ==="
mkdir -p "$GF_INSTALL_DIR"
rm -rf "$GF_INSTALL_DIR"/* || true

cd "$CRT_DIR/third_party"
rm -rf gf-complete

tar -xvzf gf-complete.tar.gz
cd "$GF_DIR"
autoreconf -if
./configure --prefix="$GF_INSTALL_DIR"
make -j6
make install

echo "=== Installing jerasure ==="
mkdir -p "$JERASURE_INSTALL_DIR"
rm -rf "$JERASURE_INSTALL_DIR"/* || true

cd "$CRT_DIR/third_party"
rm -rf jerasure

tar -xvzf jerasure.tar.gz
cd "$JERASURE_DIR"
autoreconf -if
./configure --prefix="$JERASURE_INSTALL_DIR" \
  LDFLAGS=-L"$GF_INSTALL_DIR/lib" \
  CPPFLAGS=-I"$GF_INSTALL_DIR/include"
make -j6
make install

# ---- checks ----
echo "=== Sanity checks ==="
if [ ! -f "$GF_INSTALL_DIR/lib/libgf_complete.so.1.0.0" ] && [ ! -f "$GF_INSTALL_DIR/lib/libgf_complete.so.1" ]; then
  echo "Error: gf-complete shared library not found after install." >&2
  ls -la "$GF_INSTALL_DIR/lib" >&2 || true
  exit 1
fi

if [ ! -f "$JERASURE_INSTALL_DIR/lib/libJerasure.so.2.0.0" ]; then
  echo "Error: Jerasure shared library not found after install." >&2
  ls -la "$JERASURE_INSTALL_DIR/lib" >&2 || true
  exit 1
fi

echo "Third-party install done."

echo "grpc install prefix: $GRPC_INSTALL_DIR"
if [ -d "$GRPC_INSTALL_DIR/lib/cmake/gRPC" ]; then
  echo "gRPC CMake config found: $GRPC_INSTALL_DIR/lib/cmake/gRPC"
else
  echo "Warning: gRPC CMake config not found under $GRPC_INSTALL_DIR/lib/cmake/gRPC" >&2
fi

echo "Shared libs:"
ls -l "$GF_INSTALL_DIR/lib" | head -n 20
ls -l "$JERASURE_INSTALL_DIR/lib" | head -n 20
