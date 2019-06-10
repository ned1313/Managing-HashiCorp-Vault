#!/bin/bash

sudo apt-get install -y unzip jq 

#Create a vault user 
sudo useradd --system --home /etc/vault.d --shell /bin/false vault
sudo mkdir --parents /opt/vault
sudo mkdir /etc/vault.d
sudo chown --recursive vault:vault /opt/vault

#Get the vault executable
wget --quiet https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip
unzip vault_${vault_version}_linux_amd64.zip
sudo mv vault /usr/local/bin/
sudo chmod 0755 /usr/local/bin/vault
sudo chown vault:vault /usr/local/bin/vault

#Create the systemd service file
cat << EOF > /lib/systemd/system/vault.service
[Unit]
Description=Vault Agent
Requires=network-online.target
After=network-online.target
[Service]
Restart=on-failure
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap 'cap_ipc_lock=+ep' /usr/local/bin/vault
ExecStart=/usr/local/bin/vault server -config /etc/vault.d log-level=info
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=vault
Group=vault
[Install]
WantedBy=multi-user.target
EOF

#Retrieve the mysql password
token=$(curl --silent 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true)
raw_token=$(echo $token | jq -r .access_token)
resp=$(curl --silent https://productionvault7734d34e.vault.azure.net/secrets/mysql-password/6a53ee8aee414124b3ef0eced98cb119?api-version=2016-10-01 -H "Authorization: Bearer $raw_token")
mysql_password_value=$(echo $resp | jq -r .value)

#Get the IP address of the host
ip_addr=$( ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

#Create the vault server configuration file
cat << EOF > /etc/vault.d/config.hcl
storage "mysql" {
  address = "${mysql_server}.mysql.database.azure.com:3306"
  username = "vaultsqladmin@${mysql_server}"
  password = "$mysql_password_value"
  database = "vault"
  tls_ca_file = "/etc/vault.d/certs/mysql.pem"
  ha_enabled = "true"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  cluster_address  = "$ip_addr:8201"
  tls_cert_file = "/etc/vault.d/certs/vault_cert.crt"
  tls_key_file = "/etc/vault.d/certs/vault_cert.key"
}
seal "azurekeyvault" {
  tenant_id      = "${tenant_id}"
  vault_name     = "${vault_name}"
  key_name       = "${key_name}"
}
ui=true
disable_mlock = false
api_addr = "http://$ip_addr:8200"
cluster_addr = "https://$ip_addr:8201"
EOF

sudo chown -R vault:vault /etc/vault.d
sudo chmod -R 0644 /etc/vault.d/*

#copy the certificates
sudo mkdir /etc/vault.d/certs
sudo cp /var/lib/waagent/${cert_thumb}.crt /etc/vault.d/certs/vault_cert.crt
sudo cp /var/lib/waagent/${cert_thumb}.prv /etc/vault.d/certs/vault_cert.key
sudo chown --recursive vault:vault /etc/vault.d/certs
sudo chmod 750 --recursive /etc/vault.d/certs/

#Get MySQL certificate
wget https://www.digicert.com/CACerts/BaltimoreCyberTrustRoot.crt.pem -O ~/mysql.pem
sudo cp ~/mysql.pem /etc/vault.d/certs/mysql.pem

#Start the service
sudo chmod 0664 /lib/systemd/system/vault.service
sudo systemctl daemon-reload

systemctl enable vault
systemctl start vault