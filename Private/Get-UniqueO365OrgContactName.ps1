function Get-UniqueO365OrgContactName {
    <#
    .SYNOPSIS
    Generates a unique Exchange Name for organization contacts.

    .DESCRIPTION
    Prefers the SMTP local-part for stable uniqueness and appends
    numeric suffixes when the candidate name is already reserved.

    .PARAMETER PrimarySmtpAddress
    SMTP address used to derive the preferred contact name.

    .PARAMETER DisplayName
    Fallback name when SMTP local-part is unavailable.

    .PARAMETER ReservedNames
    Case-insensitive set of names already used in Exchange.
    #>
    [CmdletBinding()]
    param(
        [string] $PrimarySmtpAddress,
        [string] $DisplayName,
        [System.Collections.Generic.HashSet[string]] $ReservedNames
    )

    $BaseName = $null
    if ($PrimarySmtpAddress -and $PrimarySmtpAddress.Contains('@')) {
        $BaseName = $PrimarySmtpAddress.Split('@')[0]
    }
    if ([string]::IsNullOrWhiteSpace($BaseName)) {
        $BaseName = $DisplayName
    }
    if ([string]::IsNullOrWhiteSpace($BaseName)) {
        $BaseName = 'Contact'
    }

    $BaseName = $BaseName.Trim()
    $Candidate = $BaseName
    $Index = 2
    while ($ReservedNames -and $ReservedNames.Contains($Candidate)) {
        $Candidate = "$BaseName-$Index"
        $Index++
    }

    if ($ReservedNames) {
        $null = $ReservedNames.Add($Candidate)
    }
    $Candidate
}
