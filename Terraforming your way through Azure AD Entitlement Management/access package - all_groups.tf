# Create an access package for our three groups
resource "azuread_access_package" "all_groups" {
  catalog_id   = azuread_access_package_catalog.blogpost.id
  display_name = "All groups"
  description  = "Provides access to the three groups we created"
}

# Associate all groups to our above acess package
resource "azuread_access_package_resource_package_association" "all_groups" {
  for_each                        = azuread_access_package_resource_catalog_association.blogpost_groups
  access_package_id               = azuread_access_package.all_groups.id
  catalog_resource_association_id = each.value.id
}

resource "azuread_group" "all_groups_requestor_group" {
  display_name     = "Group allowed to request access package All groups"
  security_enabled = true
  mail_enabled     = false
  owners           = [data.azuread_client_config.current.object_id]
}
