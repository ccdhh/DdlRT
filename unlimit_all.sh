#!/bin/bash

# Clear traffic shaping on all proxy nodes.
# Keep host list consistent with test_limit.sh
HOSTS_FILE="proxy_hosts"
USER="root"
REMOTE_COMMAND="cd /users/qiliang/UniLRC && sh test_unlimit.sh"
PARALLEL=5

echo "Clearing qdisc limits on all proxy nodes..."
sudo pdsh -R ssh -w ^$HOSTS_FILE -l $USER -f $PARALLEL "$REMOTE_COMMAND"

if [ $? -eq 0 ]; then
  echo "Done."
else
  echo "Some nodes may have failed."
fi
