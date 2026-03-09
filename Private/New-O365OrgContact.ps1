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
        [Object] $Source,
        [Object] $SourceContact,
        [System.Collections.Generic.HashSet[string]] $ReservedNames
    )
    Write-Color -Text "[+] ", "Adding ", $Source.DisplayName, " / ", $Source.PrimarySmtpAddress -Color Yellow, White, Cyan, White, Cyan
    $ContactName = Get-UniqueO365OrgContactName -PrimarySmtpAddress $Source.PrimarySmtpAddress -DisplayName $Source.DisplayName -ReservedNames $ReservedNames
    try {
        $Created = New-MailContact -DisplayName $Source.DisplayName -ExternalEmailAddress $Source.PrimarySmtpAddress -Name $ContactName -WhatIf:$WhatIfPreference -ErrorAction Stop
    } catch {
        Write-Color -Text "[e] ", "Failed to create contact. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
    }
    if ($Created) {
        $null = Set-O365OrgContact -MailContact $Created -Contact @{} -Source $Source -SourceContact $SourceContact
        [PSCustomObject] @{
            MailContact = $Created
            Name        = $ContactName
        }
    }
}
