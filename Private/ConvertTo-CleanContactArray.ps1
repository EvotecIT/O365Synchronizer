function ConvertTo-CleanContactArray {
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
