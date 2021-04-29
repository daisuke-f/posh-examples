#requires -Version 5

<#
.SYNOPSIS
Parses a pcap file and outputs its contents in useful object format on Powershell.

.PARAMETER Path
Specifies path to the pcap file to be read.

.PARAMETER UnitTestMode
This switch is used when it's under unit testing. Not useful for any other purpose.

.LINK
https://pcapng.github.io/pcapng/draft-gharris-opsawg-pcap.html
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(ParameterSetName = 'Default', Mandatory = $true, Position = 0)]
    $Path,

    [Parameter(ParameterSetName = 'UnitTest', Mandatory = $true)]
    [switch] $UnitTestMode
)

function Get-CombinedHashtable {
    $result = [Ordered]@{}

    $args |
    # Where-Object -FilterScript { $_ -is [Hashtable] } |
    ForEach-Object -Process {
        $hash = $_
        $hash.Keys | %{ $result[$_] = $hash[$_] }
    }

    return $result
}

function Read-PcapInternal {
    param(
        [Parameter(Mandatory)]
        [IO.BinaryReader]
        $Reader
    )

    $fileHeader = [Ordered]@{
        MagicNumber     = $reader.ReadInt32()
        MajorVersion    = $reader.ReadInt16()
        MinorVersion    = $reader.ReadInt16()
        Reserved1       = $reader.ReadInt32()
        Reserved2       = $reader.ReadInt32()
        SnapLen         = $reader.ReadInt32()
        LinkType        = $reader.ReadInt16()
        Fcs             = $reader.ReadInt16()
    }

    if($fileHeader.MagicNumber -eq 0xa1b2c3d4) {
        $timeUnit = 'm'
    } elseif($fileHeader.MagicNumber -eq 0xa1b23c4d) {
        $timeUnit = 'n'
    } else {
        throw [IO.FileFormatException]::new('This is not a PCAP file.')
    }

    if($fileHeader.LinkType -ne 1) {
        throw [NotImplementedException]::new(('Link type is not supported: {0}' -f $fileHeader.LinkType))
    }

    # Write-Output ([PSCustomObject]$fileHeader)

    $packetHeader = [Ordered]@{
        Timestamp   = $(
            $d = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0
            
            $seconds = $reader.ReadInt32()
            $d = $d.AddSeconds($seconds)

            $fraction = $reader.ReadInt32()
            if($timeUnit -eq 'm') {
                $d = $d.AddMilliseconds($fraction)
            } else {
                throw [NotImplementedException]::new()
            }

            Write-Output $d
        )
        CapturedPacketLength = $reader.ReadInt32()
        OriginalPacketLength = $reader.ReadInt32()
    }

    $macHeader = [Ordered]@{
        DestinationMacAddress = [Net.NetworkInformation.PhysicalAddress]::new($reader.ReadBytes(6))
        SourceMacAddress = [Net.NetworkInformation.PhysicalAddress]::new($reader.ReadBytes(6))
        EtherType = $reader.ReadInt16()
    }

    if($macHeader.EtherType -ne 8) {
        throw [NotImplementedException]::new(('EtherType not supported: {0}' -f $macHeader.EtherType))
    }

    $ipHeader = [Ordered]@{
        IpVersion = $reader.ReadBytes(4)
        InternetHeaderLength = $reader.ReadBytes(4)
        DSCP_ECN = $reader.ReadBytes(8)
        TotalLength = $reader.ReadInt16()
    }

    $tcpHeader = [Ordered]@{
        SourcePort = $reader.ReadUInt16()
        DestinationPort = $reader.ReadUInt16()
        SequenceNumber = $reader.ReadUInt32()
        AcknowledgementNumber = $reader.ReadUInt32()
        DataOffset = $reader.ReadBytes(4)
        Reserved = $reader.ReadBytes(3)
        Flags = $reader.ReadBytes(9)
        WindowSize = $reader.ReadUInt16()
    }

    Write-Output ([PSCustomObject](Get-CombinedHashtable $fileHeader $packetHeader $macHeader $ipHeader $tcpHeader))
}

function main {
    try {
        $stream = [IO.File]::OpenRead($Path)
        $reader = [IO.BinaryReader]::new($stream)

        Read-PcapInternal -Reader $reader

        $reader.Close()
        $stream.Close()
    } catch {
        throw
    } finally {
        if($null -ne $reader) { $reader.Dispose() }
        if($null -ne $stream) { $stream.Dispose() }
    }
}

if(-Not $UnitTestMode) {
    main
}