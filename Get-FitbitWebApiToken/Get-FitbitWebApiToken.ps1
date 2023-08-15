#requires -Version 6.0

function Get-FitbitWebApiToken {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)][ValidateNotNullOrEmpty()]
        [string] $ClientId,

        [parameter(Mandatory)][ValidateSet(
          "activity", "cardio_fitness", "electrocardiogram", "heartrate",
          "location", "nutrition", "oxygen_saturation", "profile",
          "respiratory_rate", "settings", "sleep", "social",
          "temperature", "weight"
        )][string[]] $Scope
    )

    function Get-Base64UrlEncoded {
        param(
            [parameter(Mandatory)][ValidateNotNull()]
            [byte[]] $Bytes
        )
        
        return (([Convert]::ToBase64String($Bytes) -replace '\+', '-') -replace '/', '_').TrimEnd('=')
    }

    # Generate a code verifier
    $bytes = [array]::CreateInstance([byte], 96)
    [Random]::new().NextBytes($bytes)
    $codeVerifier = Get-Base64UrlEncoded -Bytes $bytes

    # Generate a code challenge from the code verifier
    $sha256 = [Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($codeVerifier))
    $codeChallenge = Get-Base64UrlEncoded -Bytes $hash

    # Get authorization endpoint URL
    $auth_url = 'https://www.fitbit.com/oauth2/authorize?client_id={0}&response_type=code&code_challenge={1}&code_challenge_method=S256&scope={2}' -f @(
        $ClientId,
        $codeChallenge,
        ($Scope -join '%20')
    )

    Write-Host $auth_url
    Write-Host
    Write-Host "1. Open the above URL in a browser."
    Write-Host "2. Authorize the application (login may be needed)."
    Write-Host "3. Copy the code from the URL of the page you are redirected to."
    Write-Host

    # Get authorization code
    $code = Read-Host -Prompt "Enter the code from the URL"

    if([string]::IsNullOrWhiteSpace($code)) {
        Write-Host "No code provided."
        return $null
    }

    if($code -match '^https://.*\?code=(.*)#_=_$') {
        $code = $Matches[1]
        Write-Verbose "Extracted code from URL: $code"
    }

    # Get access token
    $iwr_params = @{
        UseBasicParsing = $true
        Method = 'POST'
        Uri = 'https://api.fitbit.com/oauth2/token'
        Body = @{
            client_id = $ClientId
            grant_type = 'authorization_code'
            code = $code
            code_verifier = $codeVerifier
        }
    }

    $resp = Invoke-WebRequest @iwr_params

    if($null -eq $resp) {
        return $null
    }

    return ($resp.Content | ConvertFrom-Json)
}
