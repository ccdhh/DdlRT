CRT_DIR=$(pwd)
set -e

#our_project
cd $CRT_DIR
mkdir -p cmake/build
cd cmake/build
# Clear cached configuration so cmake can re-detect protobuf/grpc installs.
rm -f CMakeCache.txt 2>/dev/null || sudo rm -f CMakeCache.txt
rm -rf CMakeFiles 2>/dev/null || sudo rm -rf CMakeFiles


# Debug info for protobuf/grpc discovery (helps when CACHE is cleared).
GRPC_PREFIX="$CRT_DIR/project/third_party/grpc"
echo "[compile.sh] grpc prefix expected: $GRPC_PREFIX"
if [ -d "$GRPC_PREFIX" ]; then
  echo "[compile.sh] grpc prefix exists"
else
  echo "[compile.sh] grpc prefix MISSING"
fi
PB_CFG1="$GRPC_PREFIX/lib/cmake/protobuf/ProtobufConfig.cmake"
PB_CFG2="$GRPC_PREFIX/lib64/cmake/protobuf/ProtobufConfig.cmake"
PB_CFG3="$GRPC_PREFIX/share/cmake/protobuf/ProtobufConfig.cmake"
echo "[compile.sh] protobuf config candidate: $PB_CFG1"
echo "[compile.sh] protobuf config candidate: $PB_CFG2"
echo "[compile.sh] protobuf config candidate: $PB_CFG3"
if [ -f "$PB_CFG1" ] || [ -f "$PB_CFG2" ] || [ -f "$PB_CFG3" ]; then
  echo "[compile.sh] ProtobufConfig.cmake found (one candidate)"
else
  echo "[compile.sh] ProtobufConfig.cmake NOT found in common locations"
fi

cmake ../..
make -j