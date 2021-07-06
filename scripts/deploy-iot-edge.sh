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
if [ "$#" -ne 1 ]; then
    echo "Exactly 1 positional argument is needed:"
    echo "  1. Edge device connection string."
    exit 1
fi
device_id=""
IFS=';' read -ra KEY_VALUES <<< $1
for i in "${KEY_VALUES[@]}"; do
    if ! [[ $i = DeviceId* ]]; then
        continue
    fi
    IFS='=' read -ra FIELDS <<< $i
    device_id=${FIELDS[-1]}
    break
done
script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


# Make sure 'curl' command is installed.
apt-get update && sudo apt-get -y upgrade
if ! sudo -u $real_user dpkg-query -l curl &> /dev/null; then
    apt-get install -y curl
fi
# Update apt repository sources to install 'moby-engine' from Microsoft.
if ! [[ -f "/etc/apt/sources.list.d/microsoft-prod.list" ]]; then
    sudo -u $real_user curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
    input="/etc/os-release"
    declare -A os_properties
    while IFS="=" read -ra line_tokens
    do
        value=$(sed -e 's/^"//' -e 's/"$//' <<< ${line_tokens[1]})
        os_properties[${line_tokens[0]}]=$value
    done < "$input"
    if [[ ${os_properties['ID']} =~ .*[Uu]buntu.* ]]; then
        sudo -u $real_user curl https://packages.microsoft.com/config/ubuntu/${os_properties['VERSION_ID']}/multiarch/prod.list > ./microsoft-prod.list
    elif [[ ${os_properties['ID']} =~ .*[Rr]aspbian.* ]]; then
        sudo -u $real_user curl https://packages.microsoft.com/config/debian/stretch/multiarch/prod.list > ./microsoft-prod.list
    else
        # https://docs.microsoft.com/en-us/azure/iot-edge/how-to-install-iot-edge?view=iotedge-2018-06#prerequisites
        echo "The OS ${os_properties['ID']} is not supported by Azure IoT Edge runtime!"
        exit 1
    fi
    mv ./microsoft-prod.list /etc/apt/sources.list.d/
fi
if ! [[ -f "/etc/apt/trusted.gpg.d/microsoft.gpg" ]]; then
    sudo -u $real_user curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    mv ./microsoft.gpg /etc/apt/trusted.gpg.d/
fi
apt-get update
# Make sure the moby container engine is installed
if ! sudo -u $real_user dpkg-query -l moby-engine &> /dev/null; then
    apt-get install -y moby-engine || exit 1
    # Configure container runtime settings to disable infinite logging
    python3 "${script_path}/docker-configure.py"
    systemctl restart docker
fi
groupadd docker 2> /dev/null
usermod -aG docker $real_user


# Create and import a self-signed certificate to later install it into IoT edge security daemon
# https://docs.microsoft.com/en-us/azure/iot-edge/iot-edge-certs?view=iotedge-2018-06
if ! { sudo -u $real_user dpkg-query -l libssl-dev &> /dev/null \
    && sudo -u $real_user dpkg-query -l ca-certificates &> /dev/null \
    && sudo -u $real_user dpkg-query -l ntp &> /dev/null; }; then
    apt-get install -y libssl-dev ca-certificates ntp || exit 1
fi
sudo -u $real_user openssl req -x509 -nodes -newkey rsa:4096 \
    -subj "/CN=${device_id}-ca" -keyout ./iotedge-cakey.pem -out ./iotedge-cacert.pem -days 5475
mkdir -p /usr/local/share/ca-certificates/extra
cp ./iotedge-cacert.pem /usr/local/share/ca-certificates/extra/iotedge-cacert.crt
update-ca-certificates
mkdir -p /var/secrets/iotedge
cp ./{iotedge-cacert.pem,iotedge-cakey.pem} /var/secrets/iotedge
chmod -R u+r /var/secrets/iotedge
rm ./iotedge-cacert.pem ./iotedge-cakey.pem


# Install 'iotedge' package, which contains the IoT edge runtime service.
if ! sudo -u $real_user dpkg-query -l iotedge &> /dev/null; then
    config_file_path="./config.yaml"
    rm -rf /var/lib/iotedge/hsm/certs/* /var/lib/iotedge/hsm/cert_keys/*
    apt-get install -y iotedge || exit 1
    cp /etc/iotedge/config.yaml $config_file_path
    # After editing config.yaml, move it back to '/etc/iotedge/config.yaml'
    cat $config_file_path | \
        sed -e 's/^provisioning:/#provisioning:/' \
        -e 's/^  source:/#  source:/' \
        -e 's/^  device_connection_string:/#  device_connection_string:/' \
        -e 's/^  dynamic_reprovisioning:/#  dynamic_reprovisioning:/' \
        -e 's/^certificates:/#certificates:/' \
        -e 's/^  device_ca_cert:/#  device_ca_cert:/' \
        -e 's/^  device_ca_pk:/#  device_ca_pk:/' \
        -e 's/^  trusted_ca_certs:/#  trusted_ca_certs:/' \
        -e 's/^  auto_generated_ca_lifetime_days:/#  auto_generated_ca_lifetime_days:/' \
        | tee -a $config_file_path > /dev/null
    # https://docs.microsoft.com/en-us/azure/iot-edge/how-to-manage-device-certificates?view=iotedge-2018-06
    tee -a $config_file_path > /dev/null << EOF
provisioning:
  source: "manual"
  device_connection_string: "$1"
  dynamic_reprovisioning: false

certificates:
  device_ca_cert: "file:///var/secrets/iotedge/iotedge-cacert.pem"
  device_ca_pk: "file:///var/secrets/iotedge/iotedge-cakey.pem"
  trusted_ca_certs: "file:///var/secrets/iotedge/iotedge-cacert.pem"
EOF
    cp $config_file_path /etc/iotedge/config.yaml
    chown $real_user:$real_user $config_file_path
    chown -R iotedge:iotedge /var/secrets/iotedge
    # Then apply the changes
    systemctl restart iotedge
fi


# To delete everything:
#sudo apt-get remove --purge -y iotedge && sudo rm -rf /run/iotedge /etc/logrotate.d/iotedge /etc/init.d/iotedge /etc/iotedge /etc/default/iotedge /var/lib/iotedge
# Also don't forget to clean up the stopped docker containers, networks and so on.
