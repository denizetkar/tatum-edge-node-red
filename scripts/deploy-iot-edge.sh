#!/bin/bash

curl https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list > ./microsoft-prod.list
sudo mv ./microsoft-prod.list /etc/apt/sources.list.d/
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv ./microsoft.gpg /etc/apt/trusted.gpg.d/

sudo apt-get update
dpkg-query -l moby-engine &> /dev/null
retVal=$?
if [[ retVal -ne 0 ]]; then
    sudo apt-get install -y moby-engine
fi
sudo python3 docker-configure.py
sudo service docker restart

# Create and import a self-signed certificate to later install it into IoT edge security daemon
sudo apt-get install -y libssl-dev ca-certificates ntp
openssl req -x509 -nodes -newkey rsa:4096 -subj "/CN=iotedge-ca" -keyout iotedge-cakey.pem -out iotedge-cacert.pem -days 365000
sudo mkdir /usr/local/share/ca-certificates/extra
sudo cp iotedge-cacert.pem /usr/local/share/ca-certificates/extra/iotedge-cacert.crt
sudo update-ca-certificates
sudo chmod a+r /var/secrets
sudo chown iotedge:iotedge /var/secrets/iotedge-cacert.pem /var/secrets/iotedge-cakey.pem
sudo cp {iotedge-cacert.pem,iotedge-cakey.pem} /var/secrets
sudo rm iotedge-cacert.pem iotedge-cakey.pem

sudo rm -rf /var/lib/iotedge/hsm/certs/* /var/lib/iotedge/hsm/cert_keys/*
sudo apt-get install -y iotedge
sudo cp /etc/iotedge/config.yaml ./config.yaml
sudo chmod u+w ./config.yaml
sudo chown $(id -un):$(id -gn) ./config.yaml
# After editing config.yaml, move it back to '/etc/iotedge/config.yaml'
#sudo cp ./config.yaml /etc/iotedge/config.yaml
#sudo chown iotedge:iotedge /etc/iotedge/config.yaml
# Then apply the changes
#sudo systemctl restart iotedge

# sudo apt-get install -y aziot-edge=1.2* aziot-identity-service=1.2*
# sudo cp /etc/aziot/config.toml.edge.template ./config.toml
# sudo chown $(id -un):$(id -gn) ./config.toml
# # After editing config.toml, move it to '/etc/aziot/config.toml'
# #sudo cp ./config.toml /etc/aziot/config.toml
# #sudo chown root:root /etc/aziot/config.toml
# # Then apply the changes
# #sudo iotedge config apply


# To delete everything:
#sudo apt-get remove --purge -y iotedge
#sudo rm -rf /run/iotedge /etc/logrotate.d/iotedge /etc/init.d/iotedge /etc/iotedge /etc/default/iotedge /var/lib/iotedge

#sudo apt-get remove --purge -y aziot-edge aziot-identity-service
#sudo find / \( -path /mnt/c -o -path /mnt/d \) -prune -false -o -iname iotedge -exec rm -rf {} +
#sudo rm -rf /run/iotedge /etc/logrotate.d/iotedge /etc/init.d/iotedge /etc/iotedge /etc/default/iotedge /var/lib/iotedge /var/secrets/aziot
