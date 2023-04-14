locals {
  security_groups = ["Group 1", "Group 2", "Group 3"]
}

resource "azuread_group" "security_groups" {
  for_each         = toset(local.security_groups)
  display_name     = each.key
  security_enabled = true
  mail_enabled     = false
  owners           = [data.azuread_client_config.current.object_id]
}