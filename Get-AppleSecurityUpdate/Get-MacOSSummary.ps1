#requires -Version 5

[CmdletBinding()]
param(
    [parameter(Mandatory)]
    [PSObject[]]
    $UpdateHistory
)

Set-StrictMode -Version Latest

$MAC_OS_LIST = @(
    @{ Version = 'v10.02'; ShortName = 'v10.02 (Jaguar)'; Pattern = 'Mac OS X v?10\.2'; }
    @{ Version = 'v10.03'; ShortName = 'v10.03 (Panther)'; Pattern = 'Mac OS X v?10\.3'; }
    @{ Version = 'v10.04'; ShortName = 'v10.04 (Tiger)'; Pattern = 'Mac OS X v?10\.4'; }
    @{ Version = 'v10.05'; ShortName = 'v10.05 (Leopard)'; Pattern = 'Mac OS X v?10\.5'; }
    @{ Version = 'v10.06'; ShortName = 'v10.06 (Show Leopard)'; Pattern = 'Mac OS X v?10\.6'; }
    @{ Version = 'v10.07'; ShortName = 'v10.07 (Lion)'; Pattern = 'OS X Lion v?10\.7'; }
    @{ Version = 'v10.08'; ShortName = 'v10.08 (Mountain Lion)'; Pattern = 'OS X Mountain Lion'; }
    @{ Version = 'v10.09'; ShortName = 'v10.09 (Mavericks)'; Pattern = 'OS X Mavericks'; }
    @{ Version = 'v10.10'; ShortName = 'v10.10 (Yosemite)'; Pattern = 'OS X Yosemite'; }
    @{ Version = 'v10.11'; ShortName = 'v10.11 (El Capitan)'; Pattern = 'OS X El Capitan'; }
    @{ Version = 'v10.12'; ShortName = 'v10.12 (Sierra)'; Pattern = 'macOS Sierra'; }
    @{ Version = 'v10.13'; ShortName = 'v10.13 (High Sierra)'; Pattern = 'macOS High Sierra'; }
    @{ Version = 'v10.14'; ShortName = 'v10.14 (Mojave)'; Pattern = 'macOS Mojave'; }
    @{ Version = 'v10.15'; ShortName = 'v10.15 (Catalina)'; Pattern = 'macOS Catalina'; }
    @{ Version = 'v11'; ShortName = 'v11 (Big Sur)'; Pattern = 'macOS Big Sur'}
)

$yearStat = $UpdateHistory.ReleaseDate | Measure-Object -Maximum -Minimum
$minYear = $yearStat.Minimum.Year
$maxYear = $yearStat.Maximum.Year

$MAC_OS_LIST |
ForEach-Object -Process {
    $os = $_

    [pscustomobject]@{
        'MacOS Updates' = $os.ShortName
    } |
    ForEach-Object -Process {
        $obj = $_

        $minYear..$maxYear |
        ForEach-Object -Process {
            $year = $_

            $count = $UpdateHistory |
            Where-Object -FilterScript {
                ($_.AvailableFor -match $os.Pattern) -and
                (($null -ne $_.ReleaseDate) -and ($_.ReleaseDate.Year -eq $year))
            } |
            Measure-Object |
            Select-Object -ExpandProperty Count

            $obj |
            Add-Member -MemberType NoteProperty -Name $year -Value $count
        }

        Write-Output $obj
    }
}