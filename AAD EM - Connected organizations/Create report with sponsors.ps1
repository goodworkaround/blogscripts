$accessToken = "eyJ0eXAiOiJKV1QiLCJub25jZSI6IkJHSVkzY2lTOGZtemNkeEhJeFEzUlY1T0dYdG9QWFl5VXY0ZjkwNDB0bm8iLCJhbGciOiJSUzI1NiIsIng1dCI6Imh1Tjk1SXZQZmVocTM0R3pCRFoxR1hHaXJuTSIsImtpZCI6Imh1Tjk1SXZQZmVocTM0R3pCRFoxR1hHaXJuTSJ9.eyJhdWQiOiIwMDAwMDAwMy0wMDAwLTAwMDAtYzAwMC0wMDAwMDAwMDAwMDAiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC85MzdhM2IwNS0xMjY0LTQwNmYtYWRlMS0zZjRhNDJkNGUyNmYvIiwiaWF0IjoxNTk2MDUzMDE2LCJuYmYiOjE1OTYwNTMwMTYsImV4cCI6MTU5NjA1NjkxNiwiYWNjdCI6MCwiYWNyIjoiMSIsImFpbyI6IkUyQmdZRkRvajJtdWYvZHBoY3pwaGcxaW1oVitRYk4yeFMzLzRId3VQVUIwai9lMTJ4VUEiLCJhbXIiOlsicHdkIl0sImFwcF9kaXNwbGF5bmFtZSI6IkdyYXBoIGV4cGxvcmVyIChvZmZpY2lhbCBzaXRlKSIsImFwcGlkIjoiZGU4YmM4YjUtZDlmOS00OGIxLWE4YWQtYjc0OGRhNzI1MDY0IiwiYXBwaWRhY3IiOiIwIiwiZmFtaWx5X25hbWUiOiJBZG1pbmlzdHJhdG9yIiwiZ2l2ZW5fbmFtZSI6Ik1PRCIsImlwYWRkciI6Ijg5LjguNy4yMTQiLCJuYW1lIjoiTU9EIEFkbWluaXN0cmF0b3IiLCJvaWQiOiJiMzA4OTAyOS0yYWU3LTQzYTUtYmQzYy0yM2NhZWQ1YWRmYWUiLCJwbGF0ZiI6IjMiLCJwdWlkIjoiMTAwMzIwMDBDQTZGNUJGRSIsInNjcCI6Im9wZW5pZCBwcm9maWxlIFVzZXIuUmVhZCBlbWFpbCBFbnRpdGxlbWVudE1hbmFnZW1lbnQuUmVhZC5BbGwgRW50aXRsZW1lbnRNYW5hZ2VtZW50LlJlYWRXcml0ZS5BbGwiLCJzaWduaW5fc3RhdGUiOlsia21zaSJdLCJzdWIiOiJsUmxpekJYNng5a09jY19FYWVhNG9mMDlWMjJMNzBrbkQxbkRqUDBwbWQwIiwidGVuYW50X3JlZ2lvbl9zY29wZSI6IkVVIiwidGlkIjoiOTM3YTNiMDUtMTI2NC00MDZmLWFkZTEtM2Y0YTQyZDRlMjZmIiwidW5pcXVlX25hbWUiOiJhZG1pbkBNMzY1eDg5NTk4MS5vbm1pY3Jvc29mdC5jb20iLCJ1cG4iOiJhZG1pbkBNMzY1eDg5NTk4MS5vbm1pY3Jvc29mdC5jb20iLCJ1dGkiOiJBZmhZXzhOWFFVdXZRSE93T3lUVEFBIiwidmVyIjoiMS4wIiwid2lkcyI6WyI2MmU5MDM5NC02OWY1LTQyMzctOTE5MC0wMTIxNzcxNDVlMTAiXSwieG1zX3N0Ijp7InN1YiI6IkZScEM5ZEsya1dma0ZOb2pLcU5NTjdENlFtNTlhM0VIaTFsUHowa2paU1UifSwieG1zX3RjZHQiOjE1OTI4ODI1ODd9.FgCwGHno-0S98Lj7W7hJ33A-ONrFMXd5LjKJvNkp-P6DdfdMpmWN53TFZUwqHZz8OWe4v1yjrowPtUyIBrgzH4CxyLW5ZeiTOgpkIPOUjOgZvojRq7cewb1rOkBrqF7qxSCv4lzAaxfsEq5LQA0ztUAcKG8XRgkd4FFINeyJByHTyaHz_Qyp1Q0URXFgsUoDqaaBNEtxhA_TlrkX--pxnmXue_bOXlgsl2QRjn-xeuP7lWO2QMoAptOCuRClSM_a8ekwB3vsPR7Up_DDGEbYe2zzs0sIfM0z0ygt5cWN2VqE5k8VK64RiiqvIuCivr_9VIoG1NIQm1wJvegpe4_skQ"

$restParams = @{Headers = @{Authorization = "Bearer $accessToken"}}
$endpoint = "https://graph.microsoft.com/beta/identityGovernance/entitlementManagement/connectedOrganizations/"

# Get all connected organizations
$connectedOrganizations = Invoke-RestMethod $endpoint @restParams

# Get internal and external sponsors of each connected organization and add ass properties to the existing objects
$connectedOrganizations.value | ForEach-Object {
    Add-Member -InputObject $_ -MemberType NoteProperty -Name "externalSponsors" -Value (Invoke-RestMethod ("{0}/{1}/externalSponsors" -f $endpoint, $_.id) @restParams | Select-Object -ExpandProperty Value)
    Add-Member -InputObject $_ -MemberType NoteProperty -Name "internalSponsors" -Value (Invoke-RestMethod ("{0}/{1}/internalSponsors" -f $endpoint, $_.id) @restParams | Select-Object -ExpandProperty Value)
}

# List as table
$list = $connectedOrganizations.value | Foreach {
    $org = $_
    $org.internalSponsors | ForEach-Object {
        [PSCustomObject] @{
            Type = "InternalSponsor"
            TenantId = $org.identitySources[0].tenantId
            ObjectId = $_.id
            DisplayName = $_.displayName
            userPrincipalName = $_.userPrincipalName
            mail = $_.mail
        }
    }
    $org.externalSponsors | ForEach-Object {
        [PSCustomObject] @{
            Type = "ExternalSponsor"
            TenantId = $org.identitySources[0].tenantId
            ObjectId = $_.id
            DisplayName = $_.displayName
            userPrincipalName = $_.userPrincipalName
            mail = $_.mail
        }
    }     
}

$list | ft 