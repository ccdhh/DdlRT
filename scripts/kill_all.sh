#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

pkill -9 run_datanode
pkill -9 run_proxy
pkill -9 run_coordinator
pkill -9 main_client
rm -rf ./storage/*
