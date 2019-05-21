#General parameters
cluster_name = "vault-vms"
log_level = "Error"
ui = true

#Listener
 listener "tcp" {
    address          = "0.0.0.0:8200"
    cluster_address  = "0.0.0.0:8201"
    tls_cert_file = "/etc/vault/certs/vault_cert.crt"
    tls_key_file = "/etc/vault/certs/vault_cert.key"
    tls_min_version = "tls12"
  }

#Storage
storage "mysql" {
  address = "vault-mysql-1.mysql.database.azure.com:3306"
  username = "vaultsqladmin@vault-mysql-1"
  password = "V@ultMy$QL!DB"
  database = "vault"
  tls_ca_file = "/etc/vault/certs/mysql.pem"
}