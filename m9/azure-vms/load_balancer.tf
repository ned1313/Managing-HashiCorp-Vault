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

resource "azurerm_lb_nat_pool" "ssh_vmss_nat" {
  name = "ssh"
  resource_group_name = "${azurerm_resource_group.vault.name}"
  loadbalancer_id = "${azurerm_lb.vault_lb.id}"
  protocol = "Tcp"
  frontend_port_start = 2020
  frontend_port_end = 2040
  backend_port = 22
  frontend_ip_configuration_name = "lb-pip"
}
