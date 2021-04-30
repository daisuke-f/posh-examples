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

enum EtherType {
    IPv4 = 0x0800
}

enum IPProtocol {
    TCP = 0x06
}

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

function Get-BitsSegment {
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [byte[]]
        $Value,

        [Parameter(Mandatory)]
        [byte[]]
        $BitsSegment
    )

    $totalBits = 8 * ($Value | Measure-Object | Select-Object -ExpandProperty Count)

    if($totalBits -ne ($BitsSegment | Measure-Object -Sum | Select-Object -ExpandProperty Sum)) {
        $errmsg = 'Sum of BitsSegment must be equal to {0}' -f $totalBits
        throw [ArgumentException]::new($errmsg, 'BitsSegment')
    }

    $BitsSegment |
    ForEach-Object -Process {
        $bits = $_

        $out = 0
        for($b=0; $b -lt $bits; $b++) {
            $pos = $offset + $b
            $v = ($Value[$pos -shr 3] -shr (7 - ($pos % 8))) -band 1
            $out += [math]::Pow(2, $bits - $b - 1) * $v
        }
        Write-Output $out

        $offset += $bits
    }
}

function ConvertTo-NetworkByteOrder {
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [byte[]]
        $Value
    )

    $out = 0
    for($i=0; $i -lt $Value.Count; $i++) {
        $out *= 0x100
        $out += $Value[$i]
    }

    return $out
}

function Read-PcapFileHeader {
    param(
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

    if(@(0xa1b2c3d4, 0xa1b23c4d) -notcontains $fileHeader.MagicNumber) {
        throw [IO.FileFormatException]::new('This is not a PCAP file.')
    }

    return $fileHeader
}

function Read-PcapPacketHeader {
    param(
        [IO.BinaryReader]
        $Reader,
        [switch]
        $TimeIsMillisecond
    )

    $packetHeader = [Ordered]@{
        Timestamp   = $(
            $d = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0
            
            $seconds = $reader.ReadInt32()
            $d = $d.AddSeconds($seconds)

            $fraction = $reader.ReadInt32()
            if($TimeIsMillisecond) {
                $d = $d.AddMilliseconds($fraction)
            } else {
                throw [NotImplementedException]::new()
            }

            Write-Output $d
        )
        CapturedPacketLength = $reader.ReadInt32()
        OriginalPacketLength = $reader.ReadInt32()
    }

    return $packetHeader
}

function Read-MacHeader {
    param(
        [IO.BinaryReader]
        $Reader
    )

    $macHeader = [Ordered]@{
        DestinationMacAddress = [Net.NetworkInformation.PhysicalAddress]::new($reader.ReadBytes(6))
        SourceMacAddress = [Net.NetworkInformation.PhysicalAddress]::new($reader.ReadBytes(6))
        EtherType = ,$reader.ReadBytes(2) | ConvertTo-NetworkByteOrder
    }

    return $macHeader
}

function Read-IPHeader {
    param(
        [IO.BinaryReader]
        $Reader
    )

    ($ipVersion, $internetHeaderLength) = $reader.ReadBytes(1) | Get-BitsSegment -Bits 4, 4
    ($dscp, $ecn) = $reader.ReadBytes(1) | Get-BitsSegment -Bits 6, 2
    $totalLength = ,$reader.ReadBytes(2) | ConvertTo-NetworkByteOrder
    $identification = ,$reader.ReadBytes(2) | ConvertTo-NetworkByteOrder
    ($flags, $fragmentOffset) = ,$reader.ReadBytes(2) | Get-BitsSegment -Bits 3, 13

    $ipHeader = [Ordered]@{
        IpVersion = $ipVersion
        InternetHeaderLength = $internetHeaderLength
        DSCP = $dscp
        ECN = $ecn
        TotalLength = $totalLength
        Identification = $identification
        Flags = $flags
        FragmentOffset = $fragmentOffset
        TimeToLive = $reader.ReadByte()
        Protocol = $reader.ReadByte()
        HeaderChecksum = ,$reader.ReadBytes(2) | ConvertTo-NetworkByteOrder
        SourceIpAddress = [IPAddress]::new($reader.ReadBytes(4))
        DestinationIpAddress = [IPAddress]::new($reader.ReadBytes(4))
        IPOptions = $null
    }

    $ipHeader.IPOptions = $reader.ReadBytes($ipHeader.InternetHeaderLength - 5)

    return $ipHeader
}

function Read-TCPHeader {
    param(
        [IO.BinaryReader]
        $Reader
    )

    $sourcePort = ,$reader.ReadBytes(2) | ConvertTo-NetworkByteOrder
    $destinationPort = ,$reader.ReadBytes(2) | ConvertTo-NetworkByteOrder
    $sequenceNumber = ,$reader.ReadBytes(4) | ConvertTo-NetworkByteOrder
    $acknowledgementNumber = ,$reader.ReadBytes(4) | ConvertTo-NetworkByteOrder
    ($dataOffset, $reserved, $ns) = $reader.ReadByte() | Get-BitsSegment -Bits 4, 3, 1
    ($cwr, $ece, $urg, $ack, $psh, $rst, $syn, $fin) = $reader.ReadByte() | Get-BitsSegment -Bits 1, 1, 1, 1, 1, 1, 1, 1

    $tcpHeader = [Ordered]@{
        SourcePort = $sourcePort
        DestinationPort = $destinationPort
        SequenceNumber = $sequenceNumber
        AcknowledgementNumber = $acknowledgementNumber
        WindowSize = ,$reader.ReadBytes(2) | ConvertTo-NetworkByteOrder
        Checksum = $reader.ReadBytes(2)
        UrgentPointer = $reader.ReadBytes(2)
        DataOffset = $dataOffset
        Reserved = $reserved
        NS = $ns
        CWR = $cwr
        ECE = $ece
        URG = $urg
        ACK = $ack
        PSH = $psh
        RST = $rst
        SYN = $syn
        FIN = $fin
        TCPOptions = $null
    }

    $tcpHeader.TCPOptions = $reader.ReadBytes(4 * ($tcpHeader.DataOffset-5))

    return $tcpHeader
}

function Read-PcapInternal {
    param(
        [Parameter(Mandatory)]
        [IO.BinaryReader]
        $Reader
    )

    $pcap = [PSCustomObject]@{
        Header = Read-PcapFileHeader -Reader $Reader
        Packets = @()
    }

    if($pcap.Header.LinkType -ne 1) {
        throw [NotImplementedException]::new(('Link type is not supported: {0}' -f $fileHeader.LinkType))
    }

    while(0 -le $Reader.PeekChar()) {

        $packet = @{
            Header = Read-PcapPacketHeader -Reader $Reader -TimeIsMillisecond ($pcap.Header.MagicNumber -eq 0xa1b2c3d4)
        }

        $macHeader = Read-MacHeader -Reader $Reader
        $packet.Mac = [PSCustomObject]$macHeader

        if($macHeader.EtherType -ne [EtherType]::IPv4) {
            throw [NotImplementedException]::new(('EtherType not supported: {0}' -f $macHeader.EtherType))
        }

        $ipHeader = Read-IPHeader -Reader $Reader
        $packet.IP = [PSCustomObject]$ipHeader

        if($ipHeader.Protocol -ne [IPProtocol]::TCP) {
            throw [NotImplementedException]::new(('IP Protocol not supported: {0}' -f $ipHeader.Protocol))
        }

        $tcpHeader = Read-TCPHeader -Reader $Reader
        $packet.TCP = [PSCustomObject]$tcpHeader

        $packet.Data = $Reader.ReadBytes($ipHeader.TotalLength - 4 * $ipHeader.InternetHeaderLength - 4 * $tcpHeader.DataOffset)

        $pcap.Packets += [PSCustomObject]$packet
    }
    
    Write-Output ($pcap)
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