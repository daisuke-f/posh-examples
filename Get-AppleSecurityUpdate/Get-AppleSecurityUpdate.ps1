#requires -Version 5

[CmdletBinding()]
param(
    [switch] $Execute = $True
)

Set-StrictMode -Version Latest

filter Find-HTMLTableElement {
    $_ |
    Select-String -Pattern '<table[\s\S]*?</table>' -AllMatches |
    ForEach-Object -Process { $_.Matches.Value }
}

filter ConvertTo-XmlObject {
    [xml]($_.Replace('<br>', "`n").Replace('&nbsp;', ' ').Replace('&', '&amp;').Replace('<p>', '').Replace('</p>', ''))
}

filter ConvertTo-PSObject {
    function Get-TextContent {
        param($obj)

        if ($obj -is [string]) { $obj }
        elseif ($obj -is [System.Xml.XmlElement]) { $obj.InnerText.Trim() }
        else { $obj }
    }

    # Note: "-Skip 1" means skipping table header row.
    $_.table.tbody.tr |
    Select-Object -Skip 1 -Property @(
        @{
            Name       = 'Name';
            Expression = { Get-TextContent $_.td[0] }
        }
        @{
            Name       = 'Url';
            Expression = { $_.td[0].SelectNodes('.//a') | Select-Object -Expand href }
        }
        @{
            Name       = 'AvailableFor';
            Expression = { Get-TextContent $_.td[1] }
        }
        @{
            Name       = 'ReleaseDateText';
            Expression = { Get-TextContent $_.td[2] }
        }
    )
}

filter Add-ExtraProperty {
    $_ |
    Add-Member -PassThru -NotePropertyMembers @{
        'ReleaseDate' = $(
            $d = $_.ReleaseDateText
            $d = $d -replace '^(\d{1,2}) Sept (\d{4})$', '$1 Sep $2'
            $d = $d -replace '^16 May 2005 \(client\)\s+19 May 2005 \(server\)$', '16 May 2005'

            $date = [datetime]::new(0)
            if([datetime]::TryParse($d, [ref]$date)) {
                Write-Output $date
            }
        )
    }
}

$URL_LIST = @(
    'https://support.apple.com/HT201222' <# 2016 ~ now #>
    'https://support.apple.com/HT209441' <# 2015 #>
    'https://support.apple.com/HT205762' <# 2014 #>
    'https://support.apple.com/HT205759' <# 2013 #>
    'https://support.apple.com/HT204611' <# 2011 ~ 2012 #>
    'https://support.apple.com/HT5165' <# 2010 #>
    'https://support.apple.com/HT4218' <# 2008 ~ 2009 #>
    'https://support.apple.com/HT1263' <# 2005 ~ 2007 #>
)

function main {
    param(
        $Url = $URL_LIST
    )

    $Url |
    ForEach-Object -Process {
        $url = $_

        $response = Invoke-WebRequest -Uri $url

        if ($null -eq $response) {
            return
        }

        if ($response.StatusCode -ne 200) {
            Write-Warn ('Skip HTTP status: {0})' -f $response.StatusCode)
            return
        }

        Write-Verbose ('Content-Type: {0}' -f $response.Headers['Content-Type'])
        Write-Verbose ('RawContentLength: {0}' -f $response.RawContentLength)

        $response.Content |
        Find-HTMLTableElement |
        ConvertTo-XmlObject |
        ConvertTo-PSObject |
        Add-ExtraProperty
    }
}

if($Execute) {
    main
}