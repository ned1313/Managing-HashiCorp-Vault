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
# RESOURCES
##################################################################################

# BASIC AZURE RESOURCES AND CONFIG #
resource "azurerm_resource_group" "vault" {
  name     = "${var.arm_resource_group_name}${var.environment}"
  location = "${var.arm_region}"

}

resource "random_id" "vault_rand" {
  byte_length = 4
}

resource "azurerm_user_assigned_identity" "vault_id" {
  resource_group_name = "${azurerm_resource_group.vault.name}"
  location            = "${var.arm_region}"
  name = "vault-recovery"
}


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

}

# LOAD BALANCER ITEMS #
resource "azurerm_public_ip" "lb_pip" {
  name                = "lb-pip-${random_id.vault_rand.hex}"
  location            = "${var.arm_region}"
  resource_group_name = "${azurerm_resource_group.vault.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "vault_lb" {
  name                = "lb-${random_id.vault_rand.hex}"
  location            = "${var.arm_region}"
  resource_group_name = "${azurerm_resource_group.vault.name}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "lb-pip"
    public_ip_address_id = "${azurerm_public_ip.lb_pip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "lb_be" {
  resource_group_name = "${azurerm_resource_group.vault.name}"
  loadbalancer_id     = "${azurerm_lb.vault_lb.id}"
  name                = "be-${random_id.vault_rand.hex}"
}

resource "azurerm_lb_rule" "vault_lb_rule" {
  resource_group_name            = "${azurerm_resource_group.vault.name}"
  loadbalancer_id                = "${azurerm_lb.vault_lb.id}"
  name                           = "Vault"
  protocol                       = "Tcp"
  frontend_port                  = 8200
  backend_port                   = 8200
  frontend_ip_configuration_name = "lb-pip"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.lb_be.id}"
  probe_id                       = "${azurerm_lb_probe.vault_lb_probe.id}"
}

resource "azurerm_lb_probe" "vault_lb_probe" {
  resource_group_name = "${azurerm_resource_group.vault.name}"
  loadbalancer_id     = "${azurerm_lb.vault_lb.id}"
  name                = "vault-tcp-probe"
  port                = 8200
  protocol            = "tcp"
}

resource "azurerm_lb_probe" "vault_https_probe" {
  resource_group_name = "${azurerm_resource_group.vault.name}"
  loadbalancer_id     = "${azurerm_lb.vault_lb.id}"
  name                = "vault-https-probe"
  port                = 8200
  protocol            = "https"
  request_path        = "/v1/sys/health"
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_be" {
  count                   = "${var.count}"
  network_interface_id    = "${azurerm_network_interface.vault_nic.*.id[count.index]}"
  ip_configuration_name   = "nic-${random_id.vault_rand.hex}-${count.index}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.lb_be.id}"
}

resource "azurerm_lb_nat_rule" "ssh_nat" {
    count = "${var.count}"
    resource_group_name = "${azurerm_resource_group.vault.name}"
  loadbalancer_id     = "${azurerm_lb.vault_lb.id}"
  name = "ssh-nat-${count.index}"
  protocol = "Tcp"
  frontend_port = "202${count.index}"
  backend_port = "22"
  frontend_ip_configuration_name = "lb-pip"
}

resource "azurerm_network_interface_nat_rule_association" "ssh_nat_ass" {
    count = "${var.count}"
    network_interface_id    = "${azurerm_network_interface.vault_nic.*.id[count.index]}"
  ip_configuration_name   = "nic-${random_id.vault_rand.hex}-${count.index}"
  nat_rule_id           = "${azurerm_lb_nat_rule.ssh_nat.*.id[count.index]}"
}


# KEY VAULT ITEMS #

data "azurerm_key_vault" "vault_keyvault" {
  name = "${var.vault_name}"
  resource_group_name = "${var.vault_resource_group}"
}

data "azurerm_key_vault_secret" "mysql_password" {
  name = "${var.mysql_password_name}"
  key_vault_id = "${data.azurerm_key_vault.vault_keyvault.id}"
}

data "azurerm_key_vault_secret" "vault_cert" {
  name = "${var.cert_name}"
  key_vault_id = "${data.azurerm_key_vault.vault_keyvault.id}"
}

resource "azurerm_key_vault_access_policy" "vault-recovery" {
  vault_name = "${var.vault_name}"
  resource_group_name = "${var.vault_resource_group}"

  tenant_id = "${data.azurerm_key_vault.vault_keyvault.tenant_id}"
  object_id = "${azurerm_user_assigned_identity.vault_id.principal_id}"

  certificate_permissions = [
      "get",
      "getissuers",
      "import",
      "list",
      "listissuers",
      "update",
    ]

    key_permissions = [
      "get",
      "list",
      "create",
      "delete",
      "update",
      "wrapKey",
      "unwrapKey",
    ]

    secret_permissions= [
        "get",
    ]
}

#  VIRTUAL MACHINE RESOURCES #
resource "azurerm_network_interface" "vault_nic" {
  count                     = "${var.count}"
  name                      = "nic-${random_id.vault_rand.hex}-${count.index}"
  location                  = "${var.arm_region}"
  resource_group_name       = "${azurerm_resource_group.vault.name}"
  network_security_group_id = "${azurerm_network_security_group.vault_nsg.id}"

  ip_configuration {
    name                          = "nic-${random_id.vault_rand.hex}-${count.index}"
    subnet_id                     = "${azurerm_subnet.vault.id}"
    private_ip_address_allocation = "dynamic"

  }

}

resource "azurerm_availability_set" "vault-vms" {
    name = "vault-vms"
    resource_group_name = "${azurerm_resource_group.vault.name}"
    location = "${var.arm_region}"
    managed = true

}

data "template_file" "setup" {
  template = "${file("${path.module}/vaultinstall.tpl")}"

  vars = {
    tenant_id      = "${var.arm_tenant_id}"
    vault_name     = "${var.vault_name}"
    key_name       = "${var.key_name}"
    vault_version  = "${var.vault_version}"
    mysql_server   = "${var.mysql_server_name}"
    mysql_password = "${data.azurerm_key_vault_secret.mysql_password.id}"
    cert_thumb     = "${var.certificate_thumbprint}"
    vault_domain   = "${var.vault_domain}"
  }
}

resource "azurerm_virtual_machine" "vault_vm" {
  count                 = "${var.count}"
  name                  = "${var.vm_name}-${count.index}"
  location              = "${var.arm_region}"
  resource_group_name   = "${azurerm_resource_group.vault.name}"
  network_interface_ids = ["${azurerm_network_interface.vault_nic.*.id[count.index]}"]
  vm_size               = "Standard_D2_V3"
  delete_os_disk_on_termination = true
  availability_set_id = "${azurerm_availability_set.vault-vms.id}"

  identity = {
    type         = "UserAssigned"
    identity_ids = ["${azurerm_user_assigned_identity.vault_id.id}"]
  }

  storage_os_disk {
    name              = "OsDisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.vm_name}-${count.index}"
    admin_username = "vaultadmin"
    custom_data    = "${data.template_file.setup.rendered}"
  }

  os_profile_secrets {
    source_vault_id = "${data.azurerm_key_vault.vault_keyvault.id}"

    vault_certificates {
      certificate_url = "${data.azurerm_key_vault_secret.vault_cert.id}"
    }
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/vaultadmin/.ssh/authorized_keys"
      key_data = "${file(var.ssh_key_pub)}"
    }
  }

}

resource "azurerm_mysql_virtual_network_rule" "vaultvnetrule" {
  name                = "vault-vnet-rule"
  resource_group_name = "${var.vault_resource_group}"
  server_name         = "${var.mysql_server_name}"
  subnet_id           = "${azurerm_subnet.vault.id}"
}
