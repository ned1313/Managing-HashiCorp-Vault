#Set env variables
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=AddYourVaultTokenHere

vault login

#Create five secrets
secrets='Life Universe Everything Thanks Fish'
for secret in $secrets
do
  #write secret to vault
    curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST \
 --data '{"answer": "42"}' $VAULT_ADDR/v1/secret/data/$secrets
done

#Retrieve five secrets 100 times
for value in {1..100}
do
  for secret in $secrets
  do
    #Retrieve the secret
    curl --header "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/secret/data/$secret
  done
done

#Delete five secrets
for secret in $secrets
do
  #delete secret from vault
  curl --header "X-Vault-Token: $VAULT_TOKEN" --request DELETE $VAULT_ADDR/v1/secret/data/$secret
done