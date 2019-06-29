# Managing-HashiCorp-Vault

Exercise files for use with the Pluralsight course Managing HashiCorp Vault

## Introduction

Hello! These are the exercise files to go with my Pluralsight course, [Managing HashiCorp Vault.](https://www.pluralsight.com/courses/managing-hashicorp-vault)

## Preparing for the Course

In order to use these files, there are a few things you will need to have set up.

- **Vault binary**: You will need to install the Vault binary on your local system to run commands.  You can find more information on the [Vault download page](https://www.vaultproject.io/downloads.html).
- **Terraform**: The initial deployment of the Vault server examples use Terraform for creating them in Azure.  You can find more information on the [Terraform download page](https://www.terraform.io/downloads.html).  **NOTE**: The examples were developed using Terraform v0.11.x.  If you are using the latest v0.12.x, they may not work correctly.  I will be updating this in the near future.
- **Azure subscription**: You will need an Azure subscription to deploy resources for the examples.  If you'd rather use AWS or GCP, that's fine.  You will need to create your own deployment outside of what's provided in the exercises.
- **Azure CLI**: The examples will use the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) to add resources in Azure for running Vault server on Azure VMs and in the Azure Kubernetes Service.
- **Kubernetes Tools**: These are only needed if you are planning to do the AKS deployment of Vault.  You will need `kubectl` and `helm` to perform the necessary deployment.
- **Visual Studio Code**: This is not strictly necessary.  You can use whatever IDE suits you.  VS Code is free and multi-platform, and it's what I prefer to use.

## Doing the exercises

For the Terraform deployments, you will need to fill out the `vars.tfvars.txt` file with the information necessary for deployment.  Then rename the file `vars.tfvars` and use it with your deployments.  There are also some placeholder values in the commands that you will run and I have flagged them by using `ALL_CAPS_LIKE_THIS`.  In addition to making it stand out, it also makes it super easy to cut and paste.

## Feedback

I welcome your feedback!  Please reach out to me on Twitter or log an issue on the GitHub repo.  Thanks for taking my course!