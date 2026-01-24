function ConvertTo-CleanContactArray {
    <#
    .SYNOPSIS
    Cleans contact arrays for Graph payloads.

    .DESCRIPTION
    Trims values, removes empty entries, and optionally wraps values
    as EmailAddress objects.

    .PARAMETER Values
    String values to clean.

    .PARAMETER AsEmailAddress
    When set, returns objects with an Address property.
    #>
    [CmdletBinding()]
    param(
        [string[]] $Values,
        [switch] $AsEmailAddress
    )

    $Clean = [System.Collections.Generic.List[string]]::new()
    foreach ($Value in $Values) {
        if (-not [string]::IsNullOrWhiteSpace($Value)) {
            $null = $Clean.Add($Value.Trim())
        }
    }
    if ($Clean.Count -eq 0) {
        return $null
    }

    if ($AsEmailAddress) {
        $Entries = [System.Collections.Generic.List[object]]::new()
        foreach ($Value in $Clean) {
            $null = $Entries.Add(@{ Address = $Value })
        }
        return $Entries.ToArray()
    }

    $Clean.ToArray()
}
