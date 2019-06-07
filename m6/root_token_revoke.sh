#Revoke the existing root token
vault token revoke -self
vault token lookup

#Try to log in using the root token
vault login

#Start the root token generation process
vault operator generate-root -init -pgp-key="vaultadmin1.asc"

vault operator generate-root -nonce=NONCE_VALUE

echo "ENCODED_TOKEN" | base64 --decode | gpg -u vaultadmin1 -dq
