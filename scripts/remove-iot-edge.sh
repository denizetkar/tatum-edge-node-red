#!/bin/bash


if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   exit 1
fi
# To delete everything:
apt-get remove --purge -y iotedge && rm -rf /run/iotedge /etc/logrotate.d/iotedge /etc/init.d/iotedge /etc/iotedge /etc/default/iotedge /var/lib/iotedge
# Also don't forget to clean up the stopped docker containers, networks and so on.
docker container prune -f
docker network prune -f
