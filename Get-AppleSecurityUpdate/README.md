# Summary

Fetch security update history from Apple's web site

# Examples

## Get-AppleSecurityUpdate.ps1

```
PS> $history = ./Get-AppleSecurityUpdate.ps1
PS> 
PS> $history.Count
828
PS> 
PS> $history[0]

Name            : Xcode 12.4
Url             : https://support.apple.com/kb/HT212153
AvailableFor    : macOS Catalina 10.15.4 and later
ReleaseDateText : 26 Jan 2021
ReleaseDate     : 1/26/2021 12:00:00 AM


PS> 
```

## Get-MacOSSummary.ps1

This stats says High Sierra will come to the end of support within 2020.

```
PS> ./Get-MacOSSummary.ps1 $history | Format-Table -AutoSize -Property *

MacOS Updates          2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021
-------------          ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
v10.02 (Jaguar)           2    1    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0
v10.03 (Panther)         12   10   15    5    0    0    0    0    0    0    0    0    0    0    0    0    0
v10.04 (Tiger)           10   17   22   19   19    9    0    0    0    0    0    0    0    0    0    0    0
v10.05 (Leopard)          0    0    5   17   21   16   10    3    0    0    0    0    0    0    0    0    0
v10.06 (Show Leopard)     0    0    0    0    5   14   14   10   13    3    1    0    0    0    0    0    0
v10.07 (Lion)             0    0    0    0    0    0    3   15   14   10    0    1    0    0    0    0    0
v10.08 (Mountain Lion)    0    0    0    0    0    0    0    6   18   17   12    0    1    0    0    0    0
v10.09 (Mavericks)        0    0    0    0    0    0    0    0    5   21   19    8    1    0    0    0    0
v10.10 (Yosemite)         0    0    0    0    0    0    0    0    0    5   27   15   11    0    0    0    0
v10.11 (El Capitan)       0    0    0    0    0    0    0    0    0    0    6   19   14   10    0    0    0
v10.12 (Sierra)           0    0    0    0    0    0    0    0    0    0    0    6   15   16   11    0    0
v10.13 (High Sierra)      0    0    0    0    0    0    0    0    0    0    0    0    8   20   18   11    0
v10.14 (Mojave)           0    0    0    0    0    0    0    0    0    0    0    0    0    5   21   16    0
v10.15 (Catalina)         0    0    0    0    0    0    0    0    0    0    0    0    0    0    3   22    1
v11 (Big Sur)             0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    2    0

PS> 
```
