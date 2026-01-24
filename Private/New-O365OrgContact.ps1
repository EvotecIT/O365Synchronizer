function New-O365OrgContact {
    <#
    .SYNOPSIS
    Creates an organization contact in Exchange.

    .DESCRIPTION
    Creates a mail contact and applies additional contact fields.

    .PARAMETER Source
    Source object used to populate the contact.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Object] $Source
    )
    Write-Color -Text "[+] ", "Adding ", $Source.DisplayName, " / ", $Source.PrimarySmtpAddress -Color Yellow, White, Cyan, White, Cyan
    try {
        $Created = New-MailContact -DisplayName $Source.DisplayName -ExternalEmailAddress $Source.PrimarySmtpAddress -Name $Source.Name -WhatIf:$WhatIfPreference -ErrorAction Stop
    } catch {
        Write-Color -Text "[e] ", "Failed to create contact. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
    }
    if ($Created) {
        $null = Set-O365OrgContact -MailContact $Created -Contact @{} -Source $Source -SourceContact $SourceContact
    }
}
