# Create an access package for all groups and applications we have created
resource "azuread_access_package" "everything" {
  catalog_id   = azuread_access_package_catalog.blogpost.id
  display_name = "Everything"
  description  = "Provides access to the three groups and the three applications we created"
}

# Associate all groups and applications to our above acess package
resource "azuread_access_package_resource_package_association" "everything" {
  # Waiting for bugfix: for_each                        = merge(azuread_access_package_resource_catalog_association.blogpost_groups, azuread_access_package_resource_catalog_association.blogpost_applications)
  for_each                        = azuread_access_package_resource_catalog_association.blogpost_groups
  access_package_id               = azuread_access_package.everything.id
  catalog_resource_association_id = each.value.id
}
