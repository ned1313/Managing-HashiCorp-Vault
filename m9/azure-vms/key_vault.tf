# KEY VAULT ITEMS #

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

  /*network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }*/
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

#  VIRTUAL MACHINE RESOURCES #

data "template_file" "setup" {
  template = "${file("${path.module}/vaultinstall.tpl")}"

  vars = {
    tenant_id      = "${var.arm_tenant_id}"
    vault_name     = "${azurerm_key_vault.vault.name}"
    key_name       = "${var.key_name}"
    vault_version  = "${var.vault_version}"
    mysql_server   = "${element(split(".",azurerm_mysql_server.vaultmysql.fqdn),0)}"
    mysql_password = "${azurerm_key_vault_secret.mysql_secret.id}"
    cert_thumb     = "${azurerm_key_vault_certificate.vault_cert.thumbprint}"
    vault_domain   = "${var.vault_domain}"
  }
}