#!/bin/bash

cd /users/qiliang
sudo chmod 777 -R UniLRC
cd UniLRC


# define the source directory path
SOURCE_DIR="/users/qiliang/UniLRC"

# define the hosts file path
HOSTS_FILE="hosts"

# define the remote target directory path
REMOTE_DIR="/users/qiliang/UniLRC"

# check if the hosts file exists
if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "Error: hosts file not found!"
    exit 1
fi

# iterate over each IP address in the hosts file
while read -r ip; do

    echo "Copying to host: $ip..."

    # use rsync to copy the directory
    sudo rsync -avz  --exclude='project/cmake/build/CMakeFiles' --exclude='project/cmake/build/run_client' --exclude='project/cmake/build/main_test' --exclude='project/cmake/build/main_client' --exclude='storage/*' -e ssh "$SOURCE_DIR/" "$ip:$REMOTE_DIR/"
    #rsync -avz -e ssh "$SOURCE_DIR/" "$ip:$REMOTE_DIR/"

    # check if rsync is successful
    if [ $? -eq 0 ]; then
        echo "Successfully copied to $ip!"
    else
        echo "Failed to copy to $ip!"
    fi

done < "$HOSTS_FILE"

cd /users/qiliang/UniLRC
sh generate_run_proxy.sh

echo "All done!"