# NETWORKING #
module "vnet" {
  source              = "Azure/network/azurerm"
  resource_group_name = "${azurerm_resource_group.vault.name}"
  vnet_name           = "${azurerm_resource_group.vault.name}"
  location            = "${var.arm_region}"
  address_space       = "${var.arm_network_address_space}"
  subnet_prefixes     = ["${var.arm_subnet1_address_space}"]
  subnet_names        = ["clients"]

}

resource "azurerm_subnet" "vault" {
  name                 = "vault"
  resource_group_name  = "${azurerm_resource_group.vault.name}"
  virtual_network_name = "${module.vnet.vnet_name}"
  address_prefix       = "${var.arm_subnet2_address_space}"
  service_endpoints    = ["Microsoft.Sql"]
}

resource "azurerm_network_security_group" "vault_nsg" {
  name                = "nsg-${random_id.vault_rand.hex}"
  location            = "${var.arm_region}"
  resource_group_name = "${azurerm_resource_group.vault.name}"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Vault"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8200"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "VaultHA"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8201"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "${var.environment}-${random_id.vault_rand.hex}"
  }
}