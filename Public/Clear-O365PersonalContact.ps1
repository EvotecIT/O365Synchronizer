function Clear-O365PersonalContact {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $Identity,
        [switch] $All
    )
    $CurrentContacts = Get-MgUserContact -UserId $Identity -All
    foreach ($Contact in $CurrentContacts) {
        $Guid = [guid]::Empty
        $ConversionWorked = [guid]::TryParse($Contact.FileAs, [ref]$Guid)
        if (-not $ConversionWorked) {
            if (-not $All) {
                Write-Warning -Message "Contact $($Contact.Id) is not created as part of O365Synchronizer. Skipping."
                continue
            }
        }
        Remove-MgUserContact -UserId $Identity -ContactId $Contact.Id
    }
}