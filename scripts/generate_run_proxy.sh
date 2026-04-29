#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REMOTE_DIR="${REMOTE_DIR:-DdlRT}"
SOURCE_FILE="$REPO_ROOT/small_tools/generator_sh.py"
HOSTS_FILE="$REPO_ROOT/hosts"

# check if the hosts file exists
if [ ! -f "$HOSTS_FILE" ]; then
  echo "Error: hosts file not found!"
  exit 1
fi

# read the host list from the hosts file
HOSTS=$(cat "$HOSTS_FILE")

# use scp to copy the file to all hosts
echo "Copying $SOURCE_FILE to all hosts..."
for HOST in $HOSTS; do
  echo "Copying to $HOST..."
  scp "$SOURCE_FILE" "$HOST:$REMOTE_DIR/small_tools/"
  if [ $? -eq 0 ]; then
    echo "Successfully copied to $HOST!"
  else
    echo "Failed to copy to $HOST!"
    exit 1
  fi
done

# use pdsh to run the Python script on all hosts
REMOTE_COMMAND="cd $REMOTE_DIR/small_tools/ && python generator_sh.py"
PARALLEL=50
USER="root"

echo "Running generator_sh.py on all hosts..."
pdsh -R ssh -w ^"$HOSTS_FILE" -l "$USER" -f "$PARALLEL" "$REMOTE_COMMAND"

# check if the script is successfully run
if [ $? -eq 0 ]; then
  echo "Successfully ran generator_sh.py on all hosts!"
else
  echo "Failed to run generator_sh.py on some hosts!"
  exit 1
fi

echo "All done!"