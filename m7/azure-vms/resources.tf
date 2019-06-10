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

resource "azurerm_resource_group" "vault" {
  name     = "${var.arm_resource_group_name}${var.environment}"
  location = "${var.arm_region}"

  tags = {
    environment = "${var.environment}-${random_id.vault_rand.hex}"
  }
}

resource "random_id" "vault_rand" {
  byte_length = 4
}

resource "azurerm_user_assigned_identity" "vault_id" {
  resource_group_name = "${azurerm_resource_group.vault.name}"
  location            = "${var.arm_region}"

  name = "vault-vms"
}

data "azurerm_client_config" "current" {}

# NETWORKING #
module "vnet" {
  source              = "Azure/network/azurerm"
  resource_group_name = "${azurerm_resource_group.vault.name}"
  vnet_name           = "${azurerm_resource_group.vault.name}"
  location            = "${var.arm_region}"
  address_space       = "${var.arm_network_address_space}"
  subnet_prefixes     = ["${var.arm_subnet1_address_space}"]
  subnet_names        = ["clients"]

  tags = {
    environment = "${var.environment}-${random_id.vault_rand.hex}"
  }
}

resource "azurerm_subnet" "vault" {
  name                 = "vault"
  resource_group_name  = "${azurerm_resource_group.vault.name}"
  virtual_network_name = "${module.vnet.vnet_name}"
  address_prefix       = "${var.arm_subnet2_address_space}"
  service_endpoints    = ["Microsoft.Sql"]
}

#Public IP addresses for the virtual machines
resource "azurerm_public_ip" "vault_publicip" {
  count               = "${var.count}"
  name                = "ip-${random_id.vault_rand.hex}-${count.index}"
  location            = "${var.arm_region}"
  resource_group_name = "${azurerm_resource_group.vault.name}"
  allocation_method   = "Static"
  sku                 = "Standard"

  tags {
    environment = "${var.environment}-${random_id.vault_rand.hex}"
  }
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

# Load balancer
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

# KEY VAULT #

resource "azurerm_key_vault" "vault" {
  name                        = "${var.environment}vault${random_id.vault_rand.hex}"
  location                    = "${azurerm_resource_group.vault.location}"
  resource_group_name         = "${azurerm_resource_group.vault.name}"
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = "${var.arm_tenant_id}"

  sku {
    name = "standard"
  }

  access_policy {
    tenant_id = "${var.arm_tenant_id}"
    object_id = "${data.azurerm_client_config.current.service_principal_object_id}"

    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify",
      "wrapKey",
    ]

    secret_permissions = [
      "backup",
      "delete",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
    ]

    certificate_permissions = [
      "create",
      "delete",
      "deleteissuers",
      "get",
      "getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts",
      "manageissuers",
      "setissuers",
      "update",
    ]
  }

  access_policy {
    tenant_id = "${var.arm_tenant_id}"
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

  tags {
    environment = "${var.environment}"
  }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_key" "generated" {
  name         = "${var.key_name}"
  key_vault_id = "${azurerm_key_vault.vault.id}"
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_key_vault_certificate" "vault_cert" {
  name         = "vault-cert"
  key_vault_id = "${azurerm_key_vault.vault.id}"

  certificate {
    contents = "${base64encode(file("bundle.pfx"))}"
    password = "vaultadmin"
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}

resource "azurerm_key_vault_secret" "mysql_secret" {
  name         = "mysql-password"
  value        = "${var.mysql_password}"
  key_vault_id = "${azurerm_key_vault.vault.id}"
}

output "mysql_secret_id" {
  value = "${azurerm_key_vault_secret.mysql_secret.id}"
}

output "key_vault_name" {
  value = "${azurerm_key_vault.vault.name}"
}

#  VIRTUAL MACHINES #
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
    public_ip_address_id          = "${azurerm_public_ip.vault_publicip.*.id[count.index]}"
  }

  tags {
    environment = "${var.environment}-${random_id.vault_rand.hex}"
  }
}

data "template_file" "setup" {
  template = "${file("${path.module}/vaultinstall.tpl")}"

  vars = {
    tenant_id      = "${var.arm_tenant_id}"
    vault_name     = "${azurerm_key_vault.vault.name}"
    key_name       = "${var.key_name}"
    vault_version  = "${var.vault_version}"
    mysql_server   = "${var.mysql_server_name}-${random_id.vault_rand.hex}"
    mysql_password = "${azurerm_key_vault_secret.mysql_secret.id}"
    cert_thumb     = "${azurerm_key_vault_certificate.vault_cert.thumbprint}"
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

  identity = {
    type         = "UserAssigned"
    identity_ids = ["${azurerm_user_assigned_identity.vault_id.id}"]
  }

  storage_os_disk {
    name              = "OsDisk"
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
    custom_data    = "${data.template_file.setup.*.rendered[count.index]}"
  }

  os_profile_secrets {
    source_vault_id = "${azurerm_key_vault.vault.id}"

    vault_certificates {
      certificate_url = "${azurerm_key_vault_certificate.vault_cert.secret_id}"
    }
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/vaultadmin/.ssh/authorized_keys"
      key_data = "${file(var.ssh_key_pub)}"
    }
  }

  tags {
    environment = "${var.environment}-${random_id.vault_rand.hex}"
  }
}

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
    geo_redundant_backup  = "Disabled"
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

output "cert_thumb" {
  value = "${azurerm_key_vault_certificate.vault_cert.thumbprint}"
}
