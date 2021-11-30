[CmdletBinding(SupportsShouldProcess=$True)]
Param(
    [String] $AccessToken,

    [String] $Pattern = "^AzureCloud\."
)

Write-Verbose "Getting all existing named locations"
try {
    $url = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations?`$top=999"
    $namedlocations = @{}
    while($url) {
        $r = Invoke-RestMethod $url -Headers @{Authorization = "Bearer $accesstoken"} -Verbose:$false -ErrorAction Stop
        $r.value | ForEach-Object {
            $namedlocations[$_.displayName] = $_
        }
        $url = $r.'@odata.nextLink'
    }
} catch {
    throw "Caught error when getting named locations: $($_)"
}

# Download json file
$ProgressPreference = "SilentlyContinue"
$r = Invoke-WebRequest "https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519" -UseBasicParsing -Verbose:$false
$url = [Regex]::Matches($r.Content,'"https://download.microsoft.com/(.)+json"')[-1].Value

if($url) {
    $url = $url.Trim('"')
    Write-Verbose "Downloading JSON from $url"
    $json = Invoke-RestMethod $url -ErrorAction Stop -Verbose:$false
} else {
    throw "Unable to determine url of JSON with IP addresses"
}

$filtered = $json.values | Where-Object Name -Match $pattern

Write-Verbose "Processing $(($filtered | Measure-Object).Count) locations"
if($filtered) {
    $filtered | ForEach-Object {
        $location = $_
        Write-Verbose "Processing location $($location.name)"

        # Create body
        $body = @{
            "@odata.type" = "#microsoft.graph.ipNamedLocation"
            displayName = $location.name
            ipRanges = New-Object System.Collections.ArrayList # Use list to always conver to json properly
        }

        # Add all IP ranges
        $location.properties.addressPrefixes  | ForEach-Object {
            $body.ipRanges.Add(@{
                cidrAddress = $_

            }) | Out-Null
        }
        
        if($namedlocations.ContainsKey($location.name)) {
            $namedlocation = $namedlocations[$location.name]
            
            if(Compare-Object $namedlocation.ipRanges.cidrAddress $location.properties.addressPrefixes) {
                if ($pscmdlet.ShouldProcess("Updating location $($location.name) because of diff in IP addresses")) {
                    $r = Invoke-RestMethod "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations/$($namedlocation.id)" -Method PATCH -Body ($body | ConvertTo-Json -Depth 10) -Headers @{Authorization = "Bearer $accesstoken"} -ContentType "application/json" -Verbose:$false
                }
            } else {
                Write-Verbose "Location $($location.name) already up to date"
            }
        } else {
            if ($pscmdlet.ShouldProcess("Creating location $($location.name)")) {
            $r = Invoke-RestMethod "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations" -Method POST -Body ($body | ConvertTo-Json -Depth 10) -Headers @{Authorization = "Bearer $accesstoken"} -ContentType "application/json" -Verbose:$false
            }
            if($r.id) {
                Write-Verbose "Location $($location.name) created with id $($r.id)"
            } else {
                Write-Warning "No idea what happened"
            }
        }        
    }
} else {
    throw "No matching locations for pattern $pattern"
}