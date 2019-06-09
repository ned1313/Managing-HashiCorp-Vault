##################################################################################
# VARIABLES
##################################################################################

# Azure Variables
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
variable "tenant_id" {
    default = ""
}

#Network info
variable "arm_network_address_space" {
  default = "10.0.0.0/16"
}

variable "arm_subnet1_address_space" {
  default = "10.0.0.0/24"
}

variable "arm_subnet2_address_space" {
  default = "10.0.1.0/24"
}

#Key Vault info
variable "key_name" {
    description = "Azure Key Vault key name"
    default = "generated-key"
}

variable "environment" {
    default = "Production"
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

#Template variables
variable "vault_version" {
  default = "1.1.2"
}

variable "mysql_server_name" {
  default = "vault-mysql"
}

variable "mysql_password" {
  
}
