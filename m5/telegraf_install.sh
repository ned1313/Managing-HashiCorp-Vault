#Enable MSI for Azure VM instance
az login
az vm list -g vault-azurevms --query '[].{Name:name}' -o tsv
az vm identity assign -g vault-azurevms -n 

#Download latest version of Telegraf and install it
wget https://dl.influxdata.com/telegraf/releases/telegraf_1.10.4-1_amd64.deb
sudo dpkg -i telegraf_1.10.4-1_amd64.deb

#Create a new configuration for StatsD and Azure Monitor
telegraf --input-filter statsd --output-filter azure_monitor config > azm-telegraf.conf

#Copy config and restart service
sudo cp azm-telegraf.conf /etc/telegraf/telegraf.conf
sudo systemctl stop telegraf
sudo systemctl start telegraf
sudo systemctl status telegraf

#Update Vault server config and restart service
sudo vi /etc/vault/vault_server.hcl
sudo systemctl stop vault
sudo systemctl start vault

#Unseal the Vault and run some activity through with activity generator
export VAULT_ADDR=https://vault-vms.globomantics.xyz:8200
vault status
vault operator unseal
