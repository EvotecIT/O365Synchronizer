function Sync-O365Contact {
    <#
    .SYNOPSIS
    Synchronize contacts between source and target Office 365 tenant.

    .DESCRIPTION
    Synchronize contacts between source and target Office 365 tenant.
    Get users from source tenant using Get-MgUser (Microsoft Graph) and provide them as source objects.
    You can specify domains to synchronize. If you don't specify domains, it will use all domains from source objects.
    During synchronization new contacts will be created matching given domains in target tenant on Exchange Online.
    If contact already exists, it will be updated if needed, even if it wasn't synchronized by this module.
    It will asses whether it needs to add/update/remove contacts based on provided domain names from source objects.

    .PARAMETER SourceObjects
    Source objects to synchronize. You can use Get-MgUser to get users from Microsoft Graph and provide them as source objects.
    Any filtering you apply to them is valid and doesn't have to be 1:1 conversion.

    .PARAMETER Domains
    Domains to synchronize. If not specified, it will use all domains from source objects.

    .PARAMETER SkipAdd
    Disable the adding of new contacts functionality. This is useful if you want to only update existing contacts or remove non-existing contacts.

    .PARAMETER SkipUpdate
    Disable the updating of existing contacts functionality. This is useful if you want to only add new contacts or remove non-existing contacts.

    .PARAMETER SkipRemove
    Disable the removing of non-existing contacts functionality. This is useful if you want to only add new contacts or update existing contacts.

    .EXAMPLE
    # Source tenant
    $ClientID = '9e1b3c36'
    $TenantID = 'ceb371f6'
    $ClientSecret = 'NDE8Q'

    $Credentials = [pscredential]::new($ClientID, (ConvertTo-SecureString $ClientSecret -AsPlainText -Force))
    Connect-MgGraph -ClientSecretCredential $Credentials -TenantId $TenantID -NoWelcome

    $UsersToSync = Get-MgUser | Select-Object -First 5

    # Destination tenant
    $ClientID = 'edc4302e'
    Connect-ExchangeOnline -AppId $ClientID -CertificateThumbprint '2EC710' -Organization 'xxxxx.onmicrosoft.com'
    Sync-O365Contact -SourceObjects $UsersToSync -Domains 'evotec.pl', 'gmail.com' -Verbose -WhatIf

    .NOTES
    General notes
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][Array] $SourceObjects,
        [Parameter()][Array] $Domains,
        [switch] $SkipAdd,
        [switch] $SkipUpdate,
        [switch] $SkipRemove
    )
    $StartTimeLog = Start-TimeLog
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

    $CountAdd = 0
    $CountRemove = 0
    $CountUpdate = 0

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
                if (-not $SkipUpdate) {
                    $Updated = Set-O365OrgContact -CurrentContactsCache $CurrentContactsCache -Source $Source -SourceContact $SourceContact
                    if ($Updated) {
                        $CountUpdate++
                    }
                }
            } else {
                # Contact is new
                if (-not $SkipAdd) {
                    New-O365OrgContact -Source $Source
                    $CountAdd++
                }
            }
        } else {
            #Write-Color -Text "[i] ", "Processing stopped, as no email ", $Source.DisplayName -Color Yellow, White, Red
            #New-Contact -DisplayName $Source.DisplayName -Name $Source.DisplayName -WhatIf:$WhatIfPreference
        }
    }
    if (-not $SkipRemove) {
        foreach ($C in $CurrentContactsCache.Keys) {
            $Contact = $CurrentContactsCache[$C].MailContact
            if ($SourceObjectsCache[$Contact.PrimarySmtpAddress]) {
                continue
            } else {
                Write-Color -Text "[-] ", "Removing ", $Contact.DisplayName, " / ", $Contact.PrimarySmtpAddress -Color Yellow, Red, DarkCyan, White, Cyan
                try {
                    Remove-MailContact -Identity $Contact.PrimarySmtpAddress -WhatIf:$WhatIfPreference -Confirm:$false -ErrorAction Stop
                    $CountRemove++
                } catch {
                    Write-Color -Text "[e] ", "Failed to remove contact. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
                }

            }
        }
    }
    Write-Color -Text "[i] ", "Synchronization summary: ", $CountAdd, " added, ", $CountUpdate, " updated, ", $CountRemove, " removed" -Color Yellow, White, Cyan, White, Cyan, White, Cyan, White, Cyan
    $EndTimeLog = Stop-TimeLog -Time $StartTimeLog
    Write-Color -Text "[i] ", "Finished synchronization of ", $SourceObjects.Count, " objects. ", "Time: ", $EndTimeLog -Color Yellow, White, Cyan, White, Yellow, Cyan
}