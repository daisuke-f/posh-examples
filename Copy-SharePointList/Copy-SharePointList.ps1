<#
.SYNOPSIS
    Copy a SharePoint list from one site to another via Microsoft Graph API.
#>
param(
    $Token,
    $SiteName1,
    $SiteName2,
    $ListName1,
    $ListName2
)

$header = @{
    Authorization = 'Bearer {0}' -f $Token
}

$site1 = Invoke-RestMethod -Headers $header -Uri ('https://graph.microsoft.com/v1.0/sites/{0}' -f $SiteName1)

$site2 = Invoke-RestMethod -Headers $header -Uri ('https://graph.microsoft.com/v1.0/sites/{0}' -f $SiteName2)

$lists = Invoke-RestMethod -Headers $header -Uri ('https://graph.microsoft.com/v1.0/sites/{0}/lists' -f $site1.id)

$listId1 = $lists.value |
Where-Object -FilterScript { $_.name -eq $ListName1 } |
Select-Object -First 1 -ExpandProperty id

if (-not $listId1) {
    Write-Host ('List {0} not found' -f $ListName1)
    exit
}

$list1 = Invoke-RestMethod -Headers $header -Uri ('https://graph.microsoft.com/v1.0/sites/{0}/lists/{1}?$expand=columns,items' -f $site1.id, $listId1)

$body = @{
    description = $list1.description
    displayName = $ListName2
    list        = @{
        contentTypesEnabled = $list1.list.contentTypesEnabled
        hidden              = $list1.list.hidden
        template            = $list1.list.template
    }
} | ConvertTo-Json -Depth 2

# https://learn.microsoft.com/en-us/graph/api/list-create
$list2 = Invoke-RestMethod -Headers $header -Uri ('https://graph.microsoft.com/v1.0/sites/{0}/lists' -f $site2.id) -Method Post -Body $body -ContentType 'application/json'

$DEFAULT_FIELDS = @(
    'Title'
    'Attachments'
    'ContentType'
)

$createdFields =
$list1.columns |
Where-Object -FilterScript { -Not $_.readOnly } |
Where-Object -FilterScript { $DEFAULT_FIELDS -notcontains $_.name } |
Select-Object -ExcludeProperty id |
ForEach-Object -Process {
    $column = $_

    Write-Host ('Creating column {0}' -f $column.name)

    $body = $column | ConvertTo-Json -Depth 2

    # https://learn.microsoft.com/en-us/graph/api/list-post-columns
    Invoke-RestMethod -Header $header -Uri ('https://graph.microsoft.com/v1.0/sites/{0}/lists/{1}/columns' -f $list2.parentReference.siteId, $list2.id) -Method Post -Body $body -ContentType 'application/json'
}

$fields2 = $DEFAULT_FIELDS + $createdFields.name

$list1.items |
Select-Object -ExpandProperty fields |
Select-Object -Property $fields2 |
ForEach-Object -Process {
    $item = $_

    Write-Host ('Creating item {0}' -f $item.title)

    $body = @{
        fields = $item
    } | ConvertTo-Json -Depth 2

    # https://learn.microsoft.com/en-us/graph/api/listitem-create
    $resp = Invoke-RestMethod -Header $header -Uri ('https://graph.microsoft.com/v1.0/sites/{0}/lists/{1}/items' -f $list2.parentReference.siteId, $list2.id) -Method Post -Body $body -ContentType 'application/json'
}