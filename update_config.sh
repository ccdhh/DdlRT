#!/bin/bash

# define the source directory
SOURCE_DIR="/users/qiliang/UniLRC/project/config"

# define the hosts file path
HOSTS_FILE="hosts"

# get the hostname of the local machine
LOCAL_HOST=$(hostname)

# check if the hosts file exists
if [ ! -f "$HOSTS_FILE" ]; then
  echo "Error: hosts file not found!"
  exit 1
fi

# iterate over each line in the hosts file
while read -r REMOTE_HOST; do
  # skip empty lines and the local machine
  if [ -z "$REMOTE_HOST" ] || [ "$REMOTE_HOST" = "$LOCAL_HOST" ]; then
    continue
  fi

  echo "Copying contents of $SOURCE_DIR to $REMOTE_HOST..."

  # use scp to recursively copy the contents of the source directory
  sudo scp -r "$SOURCE_DIR"/* "$REMOTE_HOST:/users/qiliang/UniLRC/project/config/"

  # check if scp is successful
  if [ $? -eq 0 ]; then
    echo "Successfully copied to $REMOTE_HOST!"
  else
    echo "Failed to copy to $REMOTE_HOST!"
  fi

done < "$HOSTS_FILE"

echo "All done!"