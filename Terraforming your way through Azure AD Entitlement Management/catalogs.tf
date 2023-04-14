resource "azuread_access_package_catalog" "blogpost" {
  display_name = "Blogpost"
  description  = "Catalog for blogpost"
  published    = true
}

# Assign all security groups we have created to our catalog
resource "azuread_access_package_resource_catalog_association" "blogpost_groups" {
  for_each               = azuread_group.security_groups
  catalog_id             = azuread_access_package_catalog.blogpost.id
  resource_origin_id     = each.value.object_id
  resource_origin_system = "AadGroup"
}

# Assign all security groups we have created to our catalog
resource "azuread_access_package_resource_catalog_association" "blogpost_applications" {
  for_each               = azuread_service_principal.applications
  catalog_id             = azuread_access_package_catalog.blogpost.id
  resource_origin_id     = each.value.object_id
  resource_origin_system = "AadApplication"
}