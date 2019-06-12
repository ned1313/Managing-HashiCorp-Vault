#Deploy the recovery vault server
terraform init
terraform plan -var-file="vars.tfvars" -out azure-vms.tfplan
terraform apply "azure-vms.tfplan"