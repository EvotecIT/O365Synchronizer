function Sync-O365Contact {
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][Array] $SourceObjects,
        [Parameter()][Array] $Domains

    )
    Write-Color -Text "[i] ", "Starting synchronization of ", $SourceObjects.Count, " objects" -Color Yellow, White, Cyan, White, Cyan

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

    [Array] $ConvertedObjects = foreach ($Source in $SourceObjects) {
        Convert-GraphObjectToContact -SourceObject $Source
    }

    $CurrentContactsCache = Get-O365ContactsFromTenant -Domains $Domains
    if ($null -eq $CurrentContactsCache) {
        return
    }

    foreach ($Object in $ConvertedObjects) {
        $Source = $Object.MailContact
        $SourceContact = $Object.Contact
        if ($Source.PrimarySmtpAddress) {
            # we only process contacts if it has mail
            $Skip = $true
            foreach ($Domain in $Domains) {
                if ($Source.PrimarySmtpAddress -like "*@$Domain") {
                    $Skip = $false
                    break
                }
            }
            if ($Skip) {
                Write-Color -Text "[s] ", "Skipping ", $Source.DisplayName, " / ", $Source.PrimarySmtpAddress, " as it's not in domains to synchronize ", $($Domains -join ', ') -Color Yellow, White, Red, White, Red
                continue
            }
            # We cache all sources to make sure we can remove users later on
            $SourceObjectsCache[$Source.PrimarySmtpAddress] = $Source

            if ($CurrentContactsCache[$Source.PrimarySmtpAddress]) {
                # Contact already exists, but lets check if the data is the same
                Set-O365OrgContact -CurrentContactsCache $CurrentContactsCache -Source $Source -SourceContact $SourceContact
            } else {
                # Contact is new
                New-O365OrgContact -Source $Source
            }
        } else {
            #Write-Color -Text "[i] ", "Processing stopped, as no email ", $Source.DisplayName -Color Yellow, White, Red
            #New-Contact -DisplayName $Source.DisplayName -Name $Source.DisplayName -WhatIf:$WhatIfPreference
        }
    }
    foreach ($C in $CurrentContactsCache.Keys) {
        $Contact = $CurrentContactsCache[$C].MailContact
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