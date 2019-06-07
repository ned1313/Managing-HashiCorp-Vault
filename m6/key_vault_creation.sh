#Log into Azure with CLI
az login
az account set --subscription "SUB_NAME"

#Create an Azure Key Vault for Key Shares
az group create -n "vault-keyvault" -l "eastus"
az keyvault create --name "vault-keyvault" --resource-group "vault-keyvault" --location "eastus"
az keyvault update --name "vault-keyvault" --resource-group "vault-keyvault" --enabled-for-deployment "true" --enabled-for-template-deployment "true"


#Grant the VAULT VM access to manipulate keys in Azure Key Vault
az vm list -g vault-azurevms --query '[].identity.principalId' -o tsv
az keyvault set-policy --name "vault-keyvault" --object-id PRINCIPAL_ID --key-permissions get list create delete update wrapKey unwrapKey

#Create a key in key vault
az keyvault key create --vault-name "vault-keyvault" --name "vault-key" --protection software --kty RSA --size 2048 --ops decrypt encrypt sign unwrapKey verify wrapKey

#Get the tenant ID for the Vault Server config
az account show --subscription "SUB_NAME" --query 'tenantId' -o tsv
