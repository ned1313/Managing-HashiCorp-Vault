#Install unzip
sudo apt install unzip -y

#Install Vault
VAULT_VERSION="1.1.2"
wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip
unzip vault_${VAULT_VERSION}_linux_amd64.zip
sudo chown root:root vault
sudo mv vault /usr/local/bin/

#Prepare for systemd
sudo useradd --system --home /etc/vault.d --shell /bin/false vault
sudo mkdir --parents /opt/vault
sudo chown --recursive vault:vault /opt/vault

sudo vi /etc/systemd/system/vault.service

#Create general config
sudo mkdir --parents /etc/vault
sudo vi /etc/vault/vault_server.hcl
sudo chown --recursive vault:vault /etc/vault
sudo chmod 640 /etc/vault/vault_server.hcl

#Adding certificates
sudo mkdir /etc/vault/certs
sudo cp ~/fullchain.pem /etc/vault/certs/vault_cert.crt
sudo cp ~/privkey.pem /etc/vault/certs/vault_cert.key
sudo chown --recursive vault:vault /etc/vault/certs
sudo chmod 750 --recursive /etc/vault/certs/

#Get MySQL certificate
wget https://www.digicert.com/CACerts/BaltimoreCyberTrustRoot.crt.pem -O ~/mysql.pem
sudo cp ~/mysql.pem /etc/vault/certs/mysql.pem

#Start service
sudo systemctl enable vault
sudo systemctl start vault

#Add entry to hosts
sudo vi /etc/hosts

#Set environment variable for vault server
export VAULT_ADDR=https://vault-vms.globomantics.xyz:8200