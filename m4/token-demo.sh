#Spin up a dev server
vault server -dev
VAULT_ADDR="http://127.0.0.1:8200"
#PowerShell
$env:VAULT_ADDR="http://127.0.0.1:8200"

#Use existing server from previous module
#Bash
VAULT_ADDR="https://vault-vms.globomantics.xyz:8200"
#PowerShell
$env:VAULT_ADDR="https://vault-vms.globomantics.xyz:8200"

#login and view token
vault login
vault token lookup
