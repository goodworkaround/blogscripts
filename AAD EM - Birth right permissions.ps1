# Client ID and secret for the app registration
$clientid = "281d6e42-99c9-44a7-a24e-c80971210fff"
$clientsecret = read-host -Prompt "Client secret"
 
# Username and password for a user with access package manager role
$username = "Entitlement.Management.Automation@tenantname.onmicrosoft.com"
$password = read-host -Prompt "Password"
 
# Any domain registered in the tenant, such as tenantname.onmicrosoft.com
$tenant = "tenantname.onmicrosoft.com"
 
#
# Should not need to be touched anything below this line:
#
$VerbosePreference = "Continue"
 
$body = "client_id=$clientid&username=$username&password=$password&grant_type=password&scope=user.read.all%20group.read.all%20EntitlementManagement.ReadWrite.All"
$token = Invoke-RestMethod "https://login.microsoftonline.com/$tenant/oauth2/v2.0/token" -Body $body -Method Post
 
$restParams = @{Headers = @{Authorization = "$($token.token_type) $($token.access_token)"}}
  
# Endpoints
$graphBase = "https://graph.microsoft.com/beta"
$endpoints = @{
    accessPackageCatalogs = "{0}/identityGovernance/entitlementManagement/accessPackageCatalogs" -f $graphBase
    accessPackages = "{0}/identityGovernance/entitlementManagement/accessPackages" -f $graphBase
    accessPackageAssignments = "{0}/identityGovernance/entitlementManagement/accessPackageAssignments" -f $graphBase
    users = "{0}/users" -f $graphBase
    groups = "{0}/groups" -f $graphBase
    accessPackageAssignmentPolicies = "{0}/identityGovernance/entitlementManagement/accessPackageAssignmentPolicies" -f $graphBase
    me = "{0}/me" -f $graphBase
    directoryObjects = "{0}/directoryObjects" -f $graphBase
    accessPackageAssignmentRequests = "{0}/identityGovernance/entitlementManagement/accessPackageAssignmentRequests" -f $graphBase
}
 
 
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
#>
function Get-GraphRequestRecursive
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [string] $url
    )
 
    Write-Debug "Fetching url $url"
    $Result = Invoke-RestMethod $url @restParams -Verbose:$false
    if($Result.value) {
        $result.value
    }
 
    # Calls itself when there is a nextlink
    if($Result.'@odata.nextLink') {
        Get-GraphRequestRecursive $Result.'@odata.nextLink'
    }
}
 
 
#
# Get all access packages with all assignment policies
#
Write-Verbose "Getting all access packages" -Verbose
$AccessPackages = New-Object System.Collections.ArrayList
 
Get-GraphRequestRecursive "$($endpoints.accessPackages)?`$expand=accessPackageAssignmentPolicies" | Foreach {
    $AccessPackages.Add($_) | Out-Null
}
 
 
 
#
# Get all access package assignment policies
#
 
$AccessPackageAssignmentPolicies = $AccessPackages | 
    ForEach-Object {$_.accessPackageAssignmentPolicies} |
    Where-Object displayName -eq "Automatic group assignment" |
    ForEach-Object {'{0}/{1}?$expand=accessPackage' -f $endpoints.accessPackageAssignmentPolicies, $_.id} |
    ForEach-Object {Invoke-RestMethod $_ @restParams}
 
 
#
# Get all assigned users to the access packages relevant for the access package assignment policies
#
Write-Verbose "Getting all users assigned to access packages having an automatic group assignment access package policy..."
$Assignments = $AccessPackageAssignmentPolicies |
    Where-Object displayName -eq "Automatic group assignment" | # Only query policies called "Automatic group assignment"
    Sort-Object -Unique -Property accessPackageId | # Can only request assignments on a per access package level, so let's only query each access package once
    ForEach-Object {
        # Build query url and run recursive get
        $url = '{0}?$filter=accessPackage/id eq ''{1}''&$expand=target' -f $endpoints.accessPackageAssignments, $_.accessPackageId 
        Get-GraphRequestRecursive -url $url
    }
 
$AssignmentsMap = @{}
$Assignments | 
    Where-Object assignmentState -in "Delivered" |
    ForEach-Object {
        if(!$AssignmentsMap.ContainsKey($_.assignmentPolicyId)) {
            $AssignmentsMap[$_.assignmentPolicyId] = New-Object System.Collections.ArrayList
        }
        $AssignmentsMap[$_.assignmentPolicyId].Add($_) | Out-Null
    }
 
 
#
# Processing all assignments by getting group members and combining with current assignments
#
Write-Verbose "Processing all assignments by getting group members and combining with current assignments..."
$ProcessedAccessPackageAssignmentPolicies = $AccessPackageAssignmentPolicies | 
    Where-Object displayName -eq "Automatic group assignment" |
    ForEach-Object {
        Write-verbose " - Processing access package assignment policy $($_.id) for access package $($_.accessPackage.displayName)"
        $obj = @{
            CurrentAssignments = $AssignmentsMap[$_.id]
            Id = $_.id
            GroupObjectId = $_.requestorSettings.allowedRequestors.id
            AccessPackageId = $_.accessPackageId
            AccessPackageName = $_.accessPackage.displayName
            GroupMembers = @()
            ShouldNotBeMembers = @()
            MissingMembers = @()
        }
 
 
        # Get all group members
        Write-verbose "   - Getting members for group $($obj.GroupObjectId)..."
        $groupUrl = "{0}/{1}/members" -f $endpoints.groups, $obj.GroupObjectId
        $obj.GroupMembers = Get-GraphRequestRecursive $groupUrl
         
        # Calculate which members should be removed or added
        $obj.MissingMembers = $obj.GroupMembers | Where-Object {$_.id -notin $obj.CurrentAssignments.target.objectid}
        $obj.ShouldNotBeMembers = $obj.CurrentAssignments | Where-Object {$_.target.objectid -notin $obj.GroupMembers.id}
 
        [PSCustomObject] $obj
    }
 
#
# Processing access package assignment policies with users that should not be members
# 
Write-Verbose "Processing access package assignment policies with users that should not be members"
 
$ProcessedAccessPackageAssignmentPolicies | 
    Where-Object ShouldNotBeMembers | 
    ForEach-Object {
        Write-Verbose " - Processing access package policy $($_.id) for access package $($_.AccessPackageName)"
        $AccessPackageName = $_.AccessPackageName
        $_.ShouldNotBeMembers | ForEach-Object {
            Write-Verbose "   - Removing user $($_.id) from access package policy $($_.AssignmentPolicyId) for access package $($AccessPackageName)"
 
            $body = @{
                requestType = "AdminRemove"
                accessPackageAssignment = @{
                    id = $_.id
                    assignmentPolicyId = $_.assignmentPolicyId
                    accessPackageId = $_.AccessPackageId
                }
            } | ConvertTo-Json
 
            Invoke-RestMethod -Method Post -Uri $endpoints.accessPackageAssignmentRequests -Body $body -ContentType "application/json" @restParams -Verbose:$false | Out-Null
        }
    }
 
 
#
# Processing access package assignment policies with missing members
# 
Write-Verbose "Processing access package assignment policies with missing members"
 
$ProcessedAccessPackageAssignmentPolicies | 
    Where-Object MissingMembers | 
    ForEach-Object {
        Write-Verbose " - Processing access package policy $($_.id)"
        $AccessPackagePolicyId = $_.Id 
        $AccessPackageId = $_.AccessPackageId
        $AccessPackageName = $_.AccessPackageName
        $_.MissingMembers | ForEach-Object {
            Write-Verbose "   - Adding user $($_.id) to access package policy $($AccessPackagePolicyId) for access package $($AccessPackageName)"
 
            $body = @{
                requestType = "AdminAdd"
                accessPackageAssignment = @{
                    targetId = $_.id
                    assignmentPolicyId = $AccessPackagePolicyId
                    accessPackageId = $AccessPackageId
                }
            } | ConvertTo-Json
 
            Invoke-RestMethod -Method Post -Uri $endpoints.accessPackageAssignmentRequests -Body $body -ContentType "application/json" @restParams -Verbose:$false | Out-Null
        }
    }