##################################################################################
# PROVIDERS
##################################################################################

provider "azurerm" {
  subscription_id = "${var.arm_subscription_id}"
  client_id       = "${var.arm_client_id}"
  client_secret   = "${var.arm_client_secret}"
  tenant_id       = "${var.arm_tenant_id}"
}

##################################################################################
# DATA
##################################################################################

##################################################################################
# RESOURCES
##################################################################################

resource "azurerm_resource_group" "rg" {
  name     = "${var.arm_resource_group_name}-azurevms"
  location = "${var.arm_region}"
}

resource "random_id" "dns" {
  byte_length = 4
  prefix = "vault"
}


# NETWORKING #
module "vnet" {
  source              = "Azure/network/azurerm"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  vnet_name           = "${azurerm_resource_group.rg.name}"
  location            = "${var.arm_region}"
  address_space       = "${var.arm_network_address_space}"
  subnet_prefixes     = ["${var.arm_subnet1_address_space}"]
  subnet_names        = ["clients"]

  tags = {
    environment = "azure-vms"
  }
}

resource "azurerm_subnet" "vault" {
  name                 = "vault"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${module.vnet.vnet_name}"
  address_prefix       = "${var.arm_subnet2_address_space}"
  service_endpoints = ["Microsoft.Sql"]
}

# VIRTUAL MACHINES #
module "vaultserver" {
  source = "Azure/compute/azurerm"
  location = "${var.arm_region}"
  vm_os_simple = "UbuntuServer"
  public_ip_dns = ["${lower(random_id.dns.b64_url)}"]
  vnet_subnet_id = "${azurerm_subnet.vault.id}"
  vm_size = "Standard_D2_V3"
  vm_hostname = "${random_id.dns.b64_url}"
  storage_account_type = "StandardSSD_LRS"
  ssh_key = "${var.ssh_key_pub}"
  admin_username = "vaultadmin"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  tags = {
      environment = "azure-vms"
  }
}

resource "azurerm_network_security_rule" "vault" {
  name = "vault-ui"
  priority = 110
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "8200"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${basename(module.vaultserver.network_security_group_id)}"
}

# MYSQL 

resource "azurerm_mysql_server" "vaultmysql" {
  name                = "vault-mysql-1"
  location            = "${var.arm_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  sku {
    name     = "GP_Gen5_2"
    capacity = 2
    tier     = "GeneralPurpose"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "vaultsqladmin"
  administrator_login_password = "${var.mysql_password}"
  version                      = "5.7"
  ssl_enforcement              = "Enabled"
}

resource "azurerm_mysql_virtual_network_rule" "vaultvnetrule" {
  name                = "vault-vnet-rule"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  server_name         = "${azurerm_mysql_server.vaultmysql.name}"
  subnet_id           = "${azurerm_subnet.vault.id}"
}

resource "azurerm_mysql_database" "vaultdb" {
  name                = "vaultdb"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  server_name         = "${azurerm_mysql_server.vaultmysql.name}"
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}