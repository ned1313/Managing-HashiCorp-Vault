#Set env variables
export VAULT_ADDR=https://vault-vms.globomantics.xyz:8200
export VAULT_TOKEN=AddYourVaultTokenHere

#Add the secret backend if it isn't there already
curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST \
 --data '{"type": "kv", "options": {"version": "1"}}' $VAULT_ADDR/v1/sys/mounts/secret

#Create five secrets
secrets='Life Universe Everything Thanks Fish'
for secret in $secrets
do
  #write secret to vault
    curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data '{"answer": "42"}' $VAULT_ADDR/v1/secret/$secret
done

#Retrieve five secrets 100 times
for value in {1..100}
do
  for secret in $secrets
  do
    #Retrieve the secret
    curl --header "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/secret/$secret -s > /dev/null
  done
done

#Delete five secrets
for secret in $secrets
do
  #delete secret from vault
  curl --header "X-Vault-Token: $VAULT_TOKEN" --request DELETE $VAULT_ADDR/v1/secret/$secret
done