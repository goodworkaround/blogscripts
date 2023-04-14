terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
  }
}

data "azuread_client_config" "current" {}