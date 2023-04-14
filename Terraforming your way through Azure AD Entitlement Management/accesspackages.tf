# Create an access package for our three applications
resource "azuread_access_package" "all_applications" {
  catalog_id   = azuread_access_package_catalog.blogpost.id
  display_name = "All applications"
  description  = "Provides access to the three applications we created"
}

# # Waiting for bugfix: # Associate all applications to our above acess package
# resource "azuread_access_package_resource_package_association" "all_applications" {
#   for_each                        = azuread_access_package_resource_catalog_association.blogpost_applications
#   access_package_id               = azuread_access_package.all_applications.id
#   catalog_resource_association_id = each.value.id
# }

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
