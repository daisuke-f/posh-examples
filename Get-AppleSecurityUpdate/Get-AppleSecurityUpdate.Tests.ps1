$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

. "$here\$sut" -Execute:$False

Describe "Get-AppleSecurityUpdate.ps1" {
    $URL_LIST |
    ForEach-Object -Process {
        $url = $_

        It "does well with URL: $url" {
            $response = Invoke-WebRequest -Uri $url
            $response.StatusCode | Should -Be 200

            $response.Content |
            Find-HTMLTableElement |
            ConvertTo-XmlObject |
            ConvertTo-PSObject |
            Add-ExtraProperty |
            Should -Not -BeNull
        }
    }
}