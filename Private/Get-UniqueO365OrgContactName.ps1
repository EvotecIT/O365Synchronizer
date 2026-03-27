function Get-PreferredO365OrgContactName {
    <#
    .SYNOPSIS
    Generates the preferred base Exchange Name for organization contacts.

    .DESCRIPTION
    Prefers the SMTP local-part for stable uniqueness and falls back
    to the display name or a generic Contact label when needed.

    .PARAMETER PrimarySmtpAddress
    SMTP address used to derive the preferred contact name.

    .PARAMETER DisplayName
    Fallback name when SMTP local-part is unavailable.
    #>
    [CmdletBinding()]
    param(
        [string] $PrimarySmtpAddress,
        [string] $DisplayName
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

    $BaseName.Trim()
}

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

    $BaseName = Get-PreferredO365OrgContactName -PrimarySmtpAddress $PrimarySmtpAddress -DisplayName $DisplayName
    $Candidate = $BaseName
    $Index = 2
    while ($ReservedNames -and $ReservedNames.Contains($Candidate)) {
        $Candidate = "$BaseName-$Index"
        $Index++
    }

    $Candidate
}
