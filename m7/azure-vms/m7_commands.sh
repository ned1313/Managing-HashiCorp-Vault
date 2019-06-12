#Deploy the vault server initially
terraform init
terraform plan -var-file="..\..\vars.tfvars" -out azure-vms.tfplan
terraform apply "azure-vms.tfplan"

#Initialize Vault server
export VAULT_ADDR=https://vault.globomantics.xyz:8200

#PowerShell
$env:VAULT_ADDR = "https://vault.globomantics.xyz:8200"

vault status
vault operator init -key-shares=3 -key-threshold=2

#Add a second vault server
terraform plan -var-file="..\..\vars.tfvars" -var "count=2" -out azure-vms.tfplan
terraform apply "azure-vms.tfplan"

#View the health for each node
curl -k https://127.0.0.1:8200/v1/sys/health | jq

#Stop the Vault service on the active node
sudo systemctl stop vault

#Start the Vault service back up
sudo systemctl start vault

#Force failback
vault operator step-down