#!/bin/bash


if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   exit 1
fi
if [ $SUDO_USER ]; then
    real_user=$SUDO_USER
else
    real_user=$(whoami)
fi
if ! [[ $# -ge 2 && $# -le 3 ]]; then
    echo "3 or 2 positional arguments are needed:"
    echo "  1. Edge device id,"
    echo "  2. Azure IoTHub name,"
    echo "  3. Deployment manifest json file path (optional, default: './manifests/deployment.json')."
    exit 1
fi


# Make sure azure cli is installed.
if ! sudo -u $real_user dpkg-query -l azure-cli &> /dev/null; then
    sudo -u $real_user curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    sudo -u $real_user az extension add --name azure-iot
    sudo -u $real_user az login
fi
sudo -u $real_user az iot edge set-modules --device-id $1 --hub-name $2 --content ${3-"./manifests/deployment.json"}
