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
        try {
            Update-MgUserContact -UserId $UserID -ContactId $Contact.Id @PropertiesToUpdate -WhatIf:$WhatIfPreference -ErrorAction Stop
        } catch {
            Write-Color -Text "[!] ", "Failed to update contact for ", $User.DisplayName, " / ", $User.Mail, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
        }
    }
}