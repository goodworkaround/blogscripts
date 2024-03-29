locals {
  applications = ["Application 1", "Application 2", "Application 3"]
}

resource "azuread_application" "applications" {
  for_each     = toset(local.applications)
  display_name = each.key
  owners           = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "applications" {
  for_each       = azuread_application.applications
  application_id = each.value.application_id
}