# Summary

Fetch security update history from Apple's web site

# Examples

## Get-AppleSecurityUpdate.ps1

```
PS /Users/daisuke/tmp/20200104/posh-examples/Get-AppleSecurityUpdate> $history = ./Get-AppleSecurityUpdate.ps1 -Verbose
VERBOSE: GET https://support.apple.com/HT201222 with 0-byte payload
VERBOSE: received -byte response of content type text/html
VERBOSE: Content-Type: text/html; charset=utf-8
VERBOSE: RawContentLength: 105117
VERBOSE: GET https://support.apple.com/HT209441 with 0-byte payload
VERBOSE: received -byte response of content type text/html
VERBOSE: Content-Type: text/html; charset=utf-8
VERBOSE: RawContentLength: 50704
VERBOSE: GET https://support.apple.com/HT205762 with 0-byte payload
VERBOSE: received 39812-byte response of content type text/html
VERBOSE: Content-Type: text/html; charset=utf-8
VERBOSE: RawContentLength: 39812
VERBOSE: GET https://support.apple.com/HT205759 with 0-byte payload
VERBOSE: received 38236-byte response of content type text/html
VERBOSE: Content-Type: text/html; charset=utf-8
VERBOSE: RawContentLength: 38236
VERBOSE: GET https://support.apple.com/HT204611 with 0-byte payload
VERBOSE: received 44043-byte response of content type text/html
VERBOSE: Content-Type: text/html; charset=utf-8
VERBOSE: RawContentLength: 44043
VERBOSE: GET https://support.apple.com/HT5165 with 0-byte payload
VERBOSE: received 43360-byte response of content type text/html
VERBOSE: Content-Type: text/html; charset=utf-8
VERBOSE: RawContentLength: 43360
VERBOSE: GET https://support.apple.com/HT4218 with 0-byte payload
VERBOSE: received -byte response of content type text/html
VERBOSE: Content-Type: text/html; charset=utf-8
VERBOSE: RawContentLength: 56314
VERBOSE: GET https://support.apple.com/HT1263 with 0-byte payload
VERBOSE: received -byte response of content type text/html
VERBOSE: Content-Type: text/html; charset=utf-8
VERBOSE: RawContentLength: 61618
PS /Users/daisuke/tmp/20200104/posh-examples/Get-AppleSecurityUpdate> 
PS /Users/daisuke/tmp/20200104/posh-examples/Get-AppleSecurityUpdate> $history.Count
724
PS /Users/daisuke/tmp/20200104/posh-examples/Get-AppleSecurityUpdate> 
PS /Users/daisuke/tmp/20200104/posh-examples/Get-AppleSecurityUpdate> $history[0]

Name            : iCloud for Windows 10.9.1
                  
                  This update has no published CVE entries.
Url             : 
AvailableFor    : Windows 10 and later via the Microsoft Store
ReleaseDateText : 08 Jan 2020
ReleaseDate     : 2020/01/08 0:00:00


PS /Users/daisuke/tmp/20200104/posh-examples/Get-AppleSecurityUpdate> 
PS /Users/daisuke/tmp/20200104/posh-examples/Get-AppleSecurityUpdate> $history[723]

Name            : Security Update 2005-001
Url             : http://support.apple.com/kb/TA22859
AvailableFor    : Mac OS X 10.3.7                                       , Mac OS X Server 10.3.7 
                              Mac OS X 10.2.8                                   , Mac OS X Server 10.2.8
ReleaseDateText : 25 Jan 2005
ReleaseDate     : 2005/01/25 0:00:00


PS /Users/daisuke/tmp/20200104/posh-examples/Get-AppleSecurityUpdate> 
```

## Get-MacOSSummary.ps1

This stats says High Sierra will come to the end of support within 2020.

```
PS /Users/daisuke/tmp/20200104/posh-examples/Get-AppleSecurityUpdate> ./Get-MacOSSummary.ps1 $history | Format-Table -AutoSize -Property *

MacOS Updates          2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020
-------------          ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
v10.02 (Jaguar)           2    1    0    0    0    0    0    0    0    0    0    0    0    0    0    0
v10.03 (Panther)         12   10   15    5    0    0    0    0    0    0    0    0    0    0    0    0
v10.04 (Tiger)           10   17   22   19   19    9    0    0    0    0    0    0    0    0    0    0
v10.05 (Leopard)          0    0    5   17   21   16   10    3    0    0    0    0    0    0    0    0
v10.06 (Show Leopard)     0    0    0    0    5   14   14   10   13    3    1    0    0    0    0    0
v10.07 (Lion)             0    0    0    0    0    0    3   15   14   10    0    1    0    0    0    0
v10.08 (Mountain Lion)    0    0    0    0    0    0    0    6   18   17   12    0    1    0    0    0
v10.09 (Mavericks)        0    0    0    0    0    0    0    0    5   21   19    8    1    0    0    0
v10.10 (Yosemite)         0    0    0    0    0    0    0    0    0    5   27   15   11    0    0    0
v10.11 (El Capitan)       0    0    0    0    0    0    0    0    0    0    6   19   14   10    0    0
v10.12 (Sierra)           0    0    0    0    0    0    0    0    0    0    0    6   15   16   11    0
v10.13 (High Sierra)      0    0    0    0    0    0    0    0    0    0    0    0    8   20   18    0
v10.14 (Mojave)           0    0    0    0    0    0    0    0    0    0    0    0    0    5   21    0
v10.15 (Catalina)         0    0    0    0    0    0    0    0    0    0    0    0    0    0    3    0

PS /Users/daisuke/tmp/20200104/posh-examples/Get-AppleSecurityUpdate> 
```
