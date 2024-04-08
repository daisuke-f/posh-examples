<#
.SYNOPSIS
    Copy a SharePoint page from one site to another via Microsoft Graph API.
#>
param(
    $Token,
    $SiteName1,
    $SiteName2,
    $PageName1,
    $PageName2
)

$header = @{
    Authorization = 'Bearer {0}' -f $Token
}

$site1 = Invoke-RestMethod -Headers $header -Uri ('https://graph.microsoft.com/v1.0/sites/{0}' -f $SiteName1)

if(-not $site1) {
    Write-Error "Site '$SiteName1' not found."
    return
}

$site2 = Invoke-RestMethod -Headers $header -Uri ('https://graph.microsoft.com/v1.0/sites/{0}' -f $SiteName2)

if(-not $site2) {
    Write-Error "Site '$SiteName2' not found."
    return
}

# @see https://learn.microsoft.com/en-us/graph/api/sitepage-create?view=graph-rest-beta&tabs=http#request-body
$header['Accept'] = 'application/json;odata.metadata=none'

# @see https://learn.microsoft.com/en-us/graph/api/sitepage-get
$pageList1 = Invoke-RestMethod -Headers $header -Uri ('https://graph.microsoft.com/beta/sites/{0}/pages/microsoft.graph.sitePage' -f $site1.id)

$pageId = $pageList1.value | Where-Object -FilterScript { $_.name -eq $PageName1 } | Select-Object -First 1 -ExpandProperty id

if(-not $pageId) {
    Write-Error "Page '$PageName1' not found."
    return
}

# @see https://learn.microsoft.com/en-us/graph/api/sitepage-get
$page1 = Invoke-RestMethod -Headers $header -Uri ('https://graph.microsoft.com/beta/sites/{0}/pages/{1}/microsoft.graph.sitePage?$expand=canvasLayout' -f $site1.id, $pageId)

$body = $page1 |
    Select-Object -Property @(
        @{
            Name = '@odata.type'
            Expression = { 'microsoft.graph.sitePage' }
        }
        @{
            Name = 'name'
            Expression = { $PageName2 }
        }
        'title'
        'pageLayout'
        'showComments'
        'showRecommendation'
        @{
            Name = 'titleArea'
            Expression = {
                $_.titleArea |
                Select-Object -Property @(
                    "enableGradientEffect"
                    "imageWebUrl"
                    "layout"
                    "showAuthor"
                    "showPublishedDate"
                    "showTextBlockAboveTitle"
                    "textAboveTitle"
                    "textAlignment"
                    "imageSourceType"
                    "title"
                )
            }
        }
        'canvasLayout'
    ) | ConvertTo-Json -Depth 20

$bodyBytes = [Text.Encoding]::UTF8.GetBytes($body)

# @see https://learn.microsoft.com/en-us/graph/api/sitepage-create
$resp = Invoke-RestMethod -Headers $header -Uri ('https://graph.microsoft.com/beta/sites/{0}/pages/' -f $site2.id) -Method Post -Body $bodyBytes -ContentType 'application/json'

Write-Output $resp
