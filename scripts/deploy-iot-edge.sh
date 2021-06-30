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


# Install 'curl' command.
apt-get update && sudo apt-get upgrade
apt-get install -y curl


# Update apt repository sources to install 'moby-engine' from Microsoft
sudo -u $real_user curl https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list > ./microsoft-prod.list
mv ./microsoft-prod.list /etc/apt/sources.list.d/
sudo -u $real_user curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
mv ./microsoft.gpg /etc/apt/trusted.gpg.d/

apt-get update
sudo -u $real_user dpkg-query -l moby-engine &> /dev/null
retVal=$?
if [[ retVal -ne 0 ]]; then
    apt-get install -y moby-engine
fi
# Configure container runtime settings to disable infinite logging
python3 docker-configure.py
systemctl restart docker.service


# Create and import a self-signed certificate to later install it into IoT edge security daemon
apt-get install -y libssl-dev ca-certificates ntp
sudo -u $real_user openssl req -x509 -nodes -newkey rsa:4096 -subj "/CN=iotedge-ca" -keyout iotedge-cakey.pem -out iotedge-cacert.pem -days 365000
mkdir /usr/local/share/ca-certificates/extra
cp iotedge-cacert.pem /usr/local/share/ca-certificates/extra/iotedge-cacert.crt
update-ca-certificates
chmod a+r /var/secrets
chown iotedge:iotedge /var/secrets/iotedge-cacert.pem /var/secrets/iotedge-cakey.pem
cp {iotedge-cacert.pem,iotedge-cakey.pem} /var/secrets
rm iotedge-cacert.pem iotedge-cakey.pem


# Install 'iotedge' apt package.
rm -rf /var/lib/iotedge/hsm/certs/* /var/lib/iotedge/hsm/cert_keys/*
apt-get install -y iotedge
cp /etc/iotedge/config.yaml ./config.yaml
chmod u+w ./config.yaml
chown $(id -un):$(id -gn) ./config.yaml
# After editing config.yaml, move it back to '/etc/iotedge/config.yaml'
#sudo cp ./config.yaml /etc/iotedge/config.yaml
#sudo chown iotedge:iotedge /etc/iotedge/config.yaml
# Then apply the changes
#sudo systemctl restart iotedge


# To delete everything:
#sudo apt-get remove --purge -y iotedge
#sudo rm -rf /run/iotedge /etc/logrotate.d/iotedge /etc/init.d/iotedge /etc/iotedge /etc/default/iotedge /var/lib/iotedge
