# 
# This file contains all provider information required for Terraform to connect to Azure, Azure AD and Azure DevOps.
#

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.25.0"
    }
  }
}

provider "azurerm" {
  features {}
}