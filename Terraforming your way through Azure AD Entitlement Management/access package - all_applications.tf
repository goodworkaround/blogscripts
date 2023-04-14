# Create an access package for our three applications
resource "azuread_access_package" "all_applications" {
  catalog_id   = azuread_access_package_catalog.blogpost.id
  display_name = "All applications"
  description  = "Provides access to the three applications we created"
}

# Waiting for bugfix:
# Associate all applications to our above acess package
# resource "azuread_access_package_resource_package_association" "all_applications" {
#   for_each                        = azuread_access_package_resource_catalog_association.blogpost_applications
#   access_package_id               = azuread_access_package.all_applications.id
#   catalog_resource_association_id = each.value.id
#   access_type = "00000000-0000-0000-0000-000000000000"
# }

resource "azuread_access_package_assignment_policy" "all_applications" {
  access_package_id = azuread_access_package.all_applications.id
  display_name      = "Everyone can request"
  description       = "Everyone can request"
  duration_in_days  = 90

  requestor_settings {
    scope_type = "AllExistingDirectoryMemberUsers"
  }

  approval_settings {
    approval_required = true

    approval_stage {
      approval_timeout_in_days = 14

      primary_approver {
        object_id    = azuread_group.security_groups["Group 1"].object_id
        subject_type = "groupMembers"
      }
    }
  }

  assignment_review_settings {
    enabled                        = true
    review_frequency               = "weekly"
    duration_in_days               = 3
    review_type                    = "Self"
    access_review_timeout_behavior = "keepAccess"
  }
}