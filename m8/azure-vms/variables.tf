##################################################################################
# VARIABLES
##################################################################################

# Azure Provider
variable "arm_region" {
  default = "eastus"
}

variable "arm_resource_group_name" {
  default = "vault"
}

#Provider authentication
variable "arm_subscription_id" {}

variable "arm_client_id" {}
variable "arm_tenant_id" {}
variable "arm_client_secret" {}

#Network
variable "arm_network_address_space" {
  default = "10.0.0.0/16"
}

variable "arm_subnet1_address_space" {
  default = "10.0.0.0/24"
}

variable "arm_subnet2_address_space" {
  default = "10.0.1.0/24"
}

# Key Vault
variable "vault_name" {}

variable "vault_resource_group" {}

variable "key_name" {
  description = "Azure Key Vault key name"
  default     = "generated-key"
}

variable "cert_name" {
  default = "vault-cert"
}

variable "certificate_thumbprint" {}

variable "mysql_password_name" {
  default = "mysql-password"
}


variable "environment" {
  default = "Recovery"
}

# Virtual Machine
variable "ssh_key_pub" {
  default = "~/.ssh/id_rsa.pub"
}

variable "vm_name" {
  default = "vault"
}

variable "count" {
  default = "1"
}

# Vault VM Template
variable "vault_version" {
  default = "1.1.2"
}

variable "vault_domain" {
  
}


# MySQL

variable "mysql_server_name" {

}
