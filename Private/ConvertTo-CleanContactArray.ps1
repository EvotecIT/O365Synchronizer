function ConvertTo-CleanContactArray {
    <#
    .SYNOPSIS
    Cleans contact arrays for Graph payloads.

    .DESCRIPTION
    Trims values, removes empty entries and exact repetitions, and optionally wraps values
    as EmailAddress objects.

    .PARAMETER Values
    String values to clean.

    .PARAMETER PreserveDuplicates
    Retains repetitions when comparing stored contact values with the cleaned source.

    .PARAMETER AsEmailAddress
    When set, returns objects with an Address property.
    #>
    [CmdletBinding()]
    param(
        [string[]] $Values,
        [switch] $AsEmailAddress,
        [switch] $PreserveDuplicates
    )

    $Clean = [System.Collections.Generic.List[string]]::new()
    $Seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($Value in $Values) {
        if (-not [string]::IsNullOrWhiteSpace($Value)) {
            $Trimmed = $Value.Trim()
            if ($PreserveDuplicates -or $Seen.Add($Trimmed)) {
                $null = $Clean.Add($Trimmed)
            }
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
