#!/bin/bash

# define the configuration file directory
CONFIG_DIR="/users/qiliang/DdlRT/project/config"

# define the hosts file path
HOSTS_FILE="hosts"

# check if the hosts file exists
if [[ ! -f "$HOSTS_FILE" ]]; then
  echo "Error: hosts file not found!"
  exit 1
fi

# read the host list from the hosts file
HOSTS=$(cat "$HOSTS_FILE")

# prompt the user to input the string XXX
read -p "Enter the string XXX: " XXX

# check if the input string is empty
if [[ -z "$XXX" ]]; then
  echo "Error: Input string cannot be empty!"
  exit 1
fi

# define the source and target file paths
SOURCE_FILE="$CONFIG_DIR/$XXX.xml"
TARGET_FILE="$CONFIG_DIR/parameterConfiguration.xml"

# check if the source file exists
if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Error: Source file $SOURCE_FILE does not exist!"
  exit 1
fi

# copy and overwrite the target file on the local host
echo "Copying $SOURCE_FILE to $TARGET_FILE on the local host..."
cp "$SOURCE_FILE" "$TARGET_FILE"
if [[ $? -ne 0 ]]; then
  echo "Failed to copy $SOURCE_FILE to $TARGET_FILE on the local host!"
  exit 1
fi

# use rsync to sync the modified file to all remote hosts
echo "Syncing $TARGET_FILE to all remote hosts..."
for host in $HOSTS; do
  echo "Syncing to $host..."
  rsync -avz --progress "$TARGET_FILE" "$host:$TARGET_FILE"
  if [[ $? -ne 0 ]]; then
    echo "Failed to sync $TARGET_FILE to $host!"
    exit 1
  fi
done

echo "Successfully synced $TARGET_FILE to all remote hosts!"
echo "All done!"