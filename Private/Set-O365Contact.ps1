function Set-O365Contact {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string] $UserID,
        [PSCustomObject] $User,
        [PSCustomObject] $Contact,
        [string[]] $Properties
    )
    if ($Properties.Count -gt 0) {
        $PropertiesToUpdate = [ordered] @{}
        foreach ($Property in $Properties) {
            $PropertiesToUpdate[$Property] = $User.$Property
        }
        Set-UserContact -UserId $UserID -ContactId $Contact.Id @PropertiesToUpdate -WhatIf:$WhatIfPreference
    }
}