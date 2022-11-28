$enabledbastions = az graph query --graph-query "resources | where type == 'microsoft.network/bastionhosts' | where properties.enableShareableLink == true"
$enabledbastions | ConvertFrom-Json | Select-Object -ExpandProperty data | ForEach-Object{
    $bastionname = $_.name
    $urls = az rest --url "https://management.azure.com/$($_.id)/getShareablelinks?api-version=2021-05-01" --method POST | ConvertFrom-Json
    if($urls.value) {
        $urls.value | ForEach-Object {
            [PSCustomObject] @{
                Bastion = $bastionname
                VM = $_.vm.id
                Url = $_.bsl
            }
        }
    }
}
