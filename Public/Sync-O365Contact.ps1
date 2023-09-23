function Sync-O365Contact {
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][Array] $SourceObjects,
        [Parameter()][Array] $Domains
    )

    Write-Color -Text "[i] ", "Starting synchronization of ", $SourceObjects.Count, " objects" -Color Yellow, White, Cyan, White, Cyan

    $CurrentContactsCache = [ordered]@{}
    $SourceObjectsCache = [ordered]@{}

    if (-not $Domains) {
        Write-Color -Text "[i] ", "No domains specified, will use all domains from given user base" -Color Yellow, White, Cyan
        $DomainsCache = [ordered]@{}
        [Array] $Domains = foreach ($Source in $SourceObjects) {
            if ($Source.Mail) {
                $Domain = $Source.Mail.Split('@')[1]
                if ($Domain -and -not $DomainsCache[$Domain]) {
                    $Domain
                    $DomainsCache[$Domain] = $true
                    Write-Color -Text "[i] ", "Adding ", $Domain, " to list of domains to synchronize" -Color Yellow, White, Cyan
                }
            }
        }
    }

    try {
        $CurrentContacts = Get-MailContact -ResultSize Unlimited -ErrorAction Stop
    } catch {
        Write-Color -Text "[e] ", "Failed to get current contacts. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
        return
    }
    foreach ($Contact in $CurrentContacts) {
        $Found = $false
        foreach ($Domain in $Domains) {
            if ($Contact.PrimarySmtpAddress -notlike "*@$Domain") {
                continue
            } else {
                $Found = $true
            }
        }
        if ($Found) {
            $CurrentContactsCache[$Contact.PrimarySmtpAddress] = $Contact
        }
    }

    foreach ($Source in $SourceObjects) {
        if ($Source.Mail) {
            $Skip = $true
            foreach ($Domain in $Domains) {
                if ($Source.Mail -like "*@$Domain") {
                    $Skip = $false
                    break
                }
            }
            if ($Skip) {
                Write-Color -Text "[s] ", "Skipping ", $Source.DisplayName, " / ", $Source.Mail, " as it's not in domains to synchronize ", $($Domains -join ', ') -Color Yellow, White, Red, White, Red
                continue
            }

            $SourceObjectsCache[$Source.Mail] = $Source

            if ($CurrentContactsCache[$Source.Mail]) {
                Write-Color -Text "[i] ", "Skipping ", $Source.DisplayName, " / ", $Source.Mail, " as it already exists" -Color Yellow, White, DarkCyan, White, Cyan
                continue
            }
            Write-Color -Text "[i] ", "Processing ", $Source.DisplayName, " / ", $Source.Mail -Color Yellow, White, Cyan, White, Cyan
            try {
                New-MailContact -DisplayName $Source.DisplayName -ExternalEmailAddress $Source.Mail -Name $Source.DisplayName -WhatIf:$WhatIfPreference -ErrorAction Stop
            } catch {
                Write-Color -Text "[e] ", "Failed to create contact. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
            }
        } else {
            #Write-Color -Text "[i] ", "Processing stopped, as no email ", $Source.DisplayName -Color Yellow, White, Red
            #New-Contact -DisplayName $Source.DisplayName -Name $Source.DisplayName -WhatIf:$WhatIfPreference
        }
    }
    foreach ($C in $CurrentContactsCache.Keys) {
        $Contact = $CurrentContactsCache[$C]
        if ($SourceObjectsCache[$Contact.PrimarySmtpAddress]) {
            continue
        } else {
            Write-Color -Text "[i] ", "Removing ", $Contact.DisplayName, " / ", $Contact.PrimarySmtpAddress -Color Yellow, White, DarkCyan, White, Cyan
            try {
                Remove-MailContact -Identity $Contact.PrimarySmtpAddress -WhatIf:$WhatIfPreference -Confirm:$false -ErrorAction Stop
            } catch {
                Write-Color -Text "[e] ", "Failed to remove contact. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
            }
        }
    }
}