function New-O365OrgContact {
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