#Install GnuPG and rng-tools
sudo apt install gnupg rng-tools -y
sudo rngd -r /dev/urandom

#First we have to generate our pgp keys using gpg
gpg --batch --gen-key vaultadmin1
gpg --batch --gen-key vaultadmin2
gpg --batch --gen-key vaultadmin3

gpg --list-keys

#Now we need the base64 encoded public keys to use with Vault
gpg --export vaultadmin1 | base64 > vaultadmin1.asc
gpg --export vaultadmin2 | base64 > vaultadmin2.asc
gpg --export vaultadmin3 | base64 > vaultadmin3.asc

#Now we can update the seal with our gpg keys
export VAULT_ADDR="https://vault-vms.globomantics.xyz:8200"
vault operator rekey -init -key-shares=3 -key-threshold=2 -pgp-keys="vaultadmin1.asc,vaultadmin2.asc,vaultadmin3.asc"
vault operator rekey -nonce NONCE_VALUE

#Copy out the key values to key_shares.txt

#Now seal the vault and unseal using the new key shares
vault operator seal

#Decrypt the first two keys
echo "FIRST_KEY" | base64 --decode | gpg -u vaultadmin1 -dq
echo "SECOND_KEY" | base64 --decode | gpg -u vaultadmin2 -dq

#Unseal the vault
vault operator unseal

#Clean up the keys
gpg --delete-secret-and-public-key vaultadmin1
gpg --delete-secret-and-public-key vaultadmin2
gpg --delete-secret-and-public-key vaultadmin3