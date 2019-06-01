#Connect to the Vault Server vi ssh
#Stop the Vault Server service
sudo systemctl stop vault

#Update the HCL
sudo vi /etc/vault/vault_server.hcl

#Start the Vault server
sudo systemctl start vault

#Connect to vault server and migrate the seal to Azure Key Vault
export VAULT_ADDR=https://vault-vms.globomantics.xyz:8200
vault operator unseal -migrate

#Verify migration complete in the log
sudo tail -40 /var/log/syslog

#Restart the vault service and check the seal
sudo systemctl restart vault
vault status
