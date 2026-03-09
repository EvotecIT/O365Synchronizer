function Get-UniqueO365OrgContactDisplayName {
    <#
    .SYNOPSIS
    Generates a unique display name for organization contacts.

    .DESCRIPTION
    Keeps the original display name when available and appends
    a numeric suffix (for example 2, 3, 4) when duplicates exist.

    .PARAMETER DisplayName
    Preferred visible display name for the contact.

    .PARAMETER ReservedDisplayNames
    Case-insensitive dictionary that tracks already used display names.
    #>
    [CmdletBinding()]
    param(
        [string] $DisplayName,
        [System.Collections.IDictionary] $ReservedDisplayNames
    )

    $BaseName = $DisplayName
    if ([string]::IsNullOrWhiteSpace($BaseName)) {
        $BaseName = 'Contact'
    }

    $BaseName = $BaseName.Trim()
    $Candidate = $BaseName
    $Index = 2
    while ($ReservedDisplayNames -and $ReservedDisplayNames.Contains($Candidate) -and $ReservedDisplayNames[$Candidate] -gt 0) {
        $Candidate = "$BaseName$Index"
        $Index++
    }

    if ($ReservedDisplayNames) {
        if ($ReservedDisplayNames.Contains($Candidate)) {
            $ReservedDisplayNames[$Candidate]++
        } else {
            $ReservedDisplayNames[$Candidate] = 1
        }
    }
    $Candidate
}
