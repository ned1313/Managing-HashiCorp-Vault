# MYSQL 

resource "azurerm_mysql_server" "vaultmysql" {
  name                = "${var.mysql_server_name}-${random_id.vault_rand.hex}"
  location            = "${var.arm_region}"
  resource_group_name = "${azurerm_resource_group.vault.name}"

  sku {
    name     = "GP_Gen5_2"
    capacity = 2
    tier     = "GeneralPurpose"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Enabled"
  }

  administrator_login          = "vaultsqladmin"
  administrator_login_password = "${var.mysql_password}"
  version                      = "5.7"
  ssl_enforcement              = "Enabled"
}

resource "azurerm_mysql_virtual_network_rule" "vaultvnetrule" {
  name                = "vault-vnet-rule"
  resource_group_name = "${azurerm_resource_group.vault.name}"
  server_name         = "${azurerm_mysql_server.vaultmysql.name}"
  subnet_id           = "${azurerm_subnet.vault.id}"
}

resource "azurerm_mysql_database" "vaultdb" {
  name                = "vaultdb"
  resource_group_name = "${azurerm_resource_group.vault.name}"
  server_name         = "${azurerm_mysql_server.vaultmysql.name}"
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

output "mysql_fqdn" {
  value = "${azurerm_mysql_server.vaultmysql.fqdn}"
}

output "mysql_name" {
  value = "${element(split(".",azurerm_mysql_server.vaultmysql.fqdn),0)}"
}