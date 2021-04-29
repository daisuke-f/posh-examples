. ./Read-Pcap.ps1 -UnitTestMode

Describe 'Read-Pcap' {
    It 'might work' {
        $true | Should BeTrue
    }
}