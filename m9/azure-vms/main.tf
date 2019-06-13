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
  name = "vault-vms"
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_machine_scale_set" "vault_vmss" {
  name = "vault-vmss"
  location = "${var.arm_region}"
  resource_group_name   = "${azurerm_resource_group.vault.name}"
  upgrade_policy_mode = "Manual"

  sku {
    name = "Standard_D2_V3"
    tier = "Standard"
    capacity = 3
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name_prefix  = "${var.vm_name}"
    admin_username = "vaultadmin"
    custom_data    = "${data.template_file.setup.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/vaultadmin/.ssh/authorized_keys"
      key_data = "${file(var.ssh_key_pub)}"
    }
  }

  os_profile_secrets {
    source_vault_id = "${azurerm_key_vault.vault.id}"

    vault_certificates {
      certificate_url = "${azurerm_key_vault_certificate.vault_cert.secret_id}"
    }
  }

  identity = {
    type         = "UserAssigned"
    identity_ids = ["${azurerm_user_assigned_identity.vault_id.id}"]
  }

  network_profile {
    name = "vaultnetworkprofile"
    primary = true
    network_security_group_id = "${azurerm_network_security_group.vault_nsg.id}"

    ip_configuration {
      name = "vaultprimaryipconfig"
      primary = true
      subnet_id = "${azurerm_subnet.vault.id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.lb_be.id}"]
      load_balancer_inbound_nat_rules_ids    = ["${element(azurerm_lb_nat_pool.ssh_vmss_nat.*.id, count.index)}"]
    }
  }

}
