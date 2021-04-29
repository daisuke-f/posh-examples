. ./Read-Pcap.ps1 -UnitTestMode

Describe 'Get-BitsSegment' {
    It 'works with multiple values and multipe segments' {
        # 0000 1111 1111 0000
        $out = Get-BitsSegment -Value 0x0f, 0xf0 -BitsSegment 6, 5, 5

        # 000011 11111 10000
        ,$out | Should -Be (,(3, 31, 16))
    }

    It 'works with only one segment' {
        $out = Get-BitsSegment -Value 0xcc -BitsSegment 8

        $out | Should Be 0xcc
    }

    It 'works with a segment over multiple bytes' {
        # 0000 1111 1111 0000 0000 1111
        $out = Get-BitsSegment -Value 0x0f, 0xf0, 0x0f -BitsSegment 4, 16, 4

        # 0000 1111111100000000 1111
        ,$out | Should -Be (,(0, 0xff00, 0xf))
    }

    It 'throws when bit count is wrong' {
        {
            Get-BitsSegment -Value 0xaa -BitsSegment 2, 4, 1
        } | Should -Throw
    }

    It 'accepts value from pipeline' {
        # 1110 1011 1010 1011
        $out = ,(0xeb, 0xab) | Get-BitsSegment -BitsSegment 3, 9, 4

        # 111 010111010 1011
        ,$out | Should -Be (,(7, 0xba, 0xb))
    }
}

Describe 'ConvertTo-NetworkByteOrder' {
    It 'works well' {
        $out = ,(0xff, 0x00) | ConvertTo-NetworkByteOrder

        $out | Should -Be 0xff00
    }
}
Describe 'Read-Pcap' {
    It 'might work' {
        $true | Should BeTrue
    }
}