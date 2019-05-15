#K8s variables
variable "aks_prefix" {
  description = "A prefix used for all resources in this example"
}


variable "kubernetes_client_id" {
  description = "The Client ID for the Service Principal to use for this Managed Kubernetes Cluster"
}

variable "kubernetes_client_secret" {
  description = "The Client Secret for the Service Principal to use for this Managed Kubernetes Cluster"
}

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
