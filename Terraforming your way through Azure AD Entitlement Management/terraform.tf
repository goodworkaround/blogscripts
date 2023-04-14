terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
  }
}

provider "azuread" {
    tenant_id = var.tenantid
    client_id = var.clientid
    client_secret = var.clientsecret
}

data "azuread_client_config" "current" {}