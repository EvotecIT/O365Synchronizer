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
    New contacts get a unique internal Exchange Name by default, and you can opt in to unique visible display names for homonyms.

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

    .PARAMETER LogPath
    Path to the log file.

    .PARAMETER LogMaximum
    Maximum number of log files to keep.

    .PARAMETER EnsureUniqueDisplayName
    Makes visible org-contact display names unique by appending a numeric
    suffix when duplicates are detected during synchronization.

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

    .EXAMPLE
    # Use all domains from source objects
    $UsersToSync = Get-MgUser -All
    Sync-O365Contact -SourceObjects $UsersToSync -Verbose -WhatIf

    .EXAMPLE
    # Skip removals and log actions
    Sync-O365Contact -SourceObjects $UsersToSync -Domains 'evotec.pl' -SkipRemove -LogPath 'C:\Logs\O365Sync.log' -LogMaximum 10 -Verbose

    .EXAMPLE
    # Make visible display names unique for homonyms
    Sync-O365Contact -SourceObjects $UsersToSync -Domains 'evotec.pl' -EnsureUniqueDisplayName -Verbose

    .NOTES
    General notes
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][Array] $SourceObjects,
        [Parameter()][Array] $Domains,
        [switch] $SkipAdd,
        [switch] $SkipUpdate,
        [switch] $SkipRemove,
        [string] $LogPath,
        [int] $LogMaximum,
        [switch] $EnsureUniqueDisplayName
    )
    # this won't be logged to file
    Write-Color -Text "[i] ", "Starting synchronization of ", $SourceObjects.Count, " objects" -Color Yellow, White, Cyan, White, Cyan

    # lets enable global logging
    Set-LoggingCapabilities -LogPath $LogPath -LogMaximum $LogMaximum

    $StartTimeLog = Start-TimeLog
    # we repeat it here, as we want to log it to file if needed
    Write-Color -Text "[i] ", "Starting synchronization of ", $SourceObjects.Count, " objects" -Color Yellow, White, Cyan, White, Cyan -NoConsoleOutput

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

    $CurrentContactsInfo = Get-O365ContactsFromTenant -Domains $Domains
    if ($null -eq $CurrentContactsInfo) {
        return
    }
    $CurrentContactsCache = $CurrentContactsInfo.ContactsCache
    $ReservedContactNames = $CurrentContactsInfo.ReservedNames
    $ReservedContactNameOwners = $CurrentContactsInfo.ReservedNameOwners
    $ReservedContactDisplayNames = $CurrentContactsInfo.ReservedDisplayNames
    $DesiredSourceAddresses = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($Object in $ConvertedObjects) {
        $Source = $Object.MailContact
        if (-not $Source.PrimarySmtpAddress) {
            continue
        }
        foreach ($Domain in $Domains) {
            if ($Source.PrimarySmtpAddress -like "*@$Domain") {
                $null = $DesiredSourceAddresses.Add([string] $Source.PrimarySmtpAddress)
                break
            }
        }
    }

    $CountAdd = 0
    $CountRemove = 0
    $CountUpdate = 0
    $PendingNameNormalizations = [System.Collections.Generic.List[object]]::new()
    $RemovedContacts = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($Object in $ConvertedObjects) {
        $Source = $Object.MailContact
        $SourceContact = $Object.Contact
        $CurrentMailContact = $null
        $PreviousDisplayName = $null
        $UniqueDisplayName = $null
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

            if ($EnsureUniqueDisplayName) {
                if ($CurrentContactsCache[$Source.PrimarySmtpAddress]) {
                    $CurrentMailContact = $CurrentContactsCache[$Source.PrimarySmtpAddress].MailContact
                }
                $PreviousDisplayName = $CurrentMailContact.DisplayName
                $DisplayNameReservations = @{}
                foreach ($DisplayNameKey in $ReservedContactDisplayNames.Keys) {
                    $DisplayNameReservations[$DisplayNameKey] = $ReservedContactDisplayNames[$DisplayNameKey]
                }
                if ($PreviousDisplayName -and $DisplayNameReservations.Contains($PreviousDisplayName)) {
                    $DisplayNameReservations[$PreviousDisplayName]--
                    if ($DisplayNameReservations[$PreviousDisplayName] -le 0) {
                        $DisplayNameReservations.Remove($PreviousDisplayName)
                    }
                }

                $UniqueDisplayName = Get-UniqueO365OrgContactDisplayName -DisplayName $Source.DisplayName -ReservedDisplayNames $DisplayNameReservations
                $Source.DisplayName = $UniqueDisplayName
                $SourceContact.DisplayName = $UniqueDisplayName
            }

            if ($CurrentContactsCache[$Source.PrimarySmtpAddress]) {
                # Contact already exists, but lets check if the data is the same
                if (-not $SkipUpdate) {
                    $Updated = Set-O365OrgContact -CurrentContactsCache $CurrentContactsCache -Source $Source -SourceContact $SourceContact
                    if ($Updated) {
                        if ($EnsureUniqueDisplayName) {
                            if ($PreviousDisplayName -and $ReservedContactDisplayNames.Contains($PreviousDisplayName)) {
                                $ReservedContactDisplayNames[$PreviousDisplayName]--
                                if ($ReservedContactDisplayNames[$PreviousDisplayName] -le 0) {
                                    $ReservedContactDisplayNames.Remove($PreviousDisplayName)
                                }
                            }
                            if ($ReservedContactDisplayNames.Contains($UniqueDisplayName)) {
                                $ReservedContactDisplayNames[$UniqueDisplayName]++
                            } else {
                                $ReservedContactDisplayNames[$UniqueDisplayName] = 1
                            }
                        }
                        $CountUpdate++
                    }
                }
            } else {
                # Contact is new
                if (-not $SkipAdd) {
                    $PreferredContactName = Get-PreferredO365OrgContactName -PrimarySmtpAddress $Source.PrimarySmtpAddress -DisplayName $Source.DisplayName
                    $ConflictingContactAddress = $null
                    $ShouldNormalizeNameAfterRemoval = $false
                    if (-not $SkipRemove -and $ReservedContactNameOwners -and $ReservedContactNameOwners[$PreferredContactName]) {
                        $ConflictingContactAddress = [string] $ReservedContactNameOwners[$PreferredContactName]
                        if ($CurrentContactsCache[$ConflictingContactAddress] -and -not $DesiredSourceAddresses.Contains($ConflictingContactAddress)) {
                            $ShouldNormalizeNameAfterRemoval = $true
                        }
                    }

                    $CreatedContact = New-O365OrgContact -Source $Source -SourceContact $SourceContact -ReservedNames $ReservedContactNames
                    if ($CreatedContact) {
                        if ($EnsureUniqueDisplayName) {
                            if ($ReservedContactDisplayNames.Contains($UniqueDisplayName)) {
                                $ReservedContactDisplayNames[$UniqueDisplayName]++
                            } else {
                                $ReservedContactDisplayNames[$UniqueDisplayName] = 1
                            }
                        }
                        if ($ShouldNormalizeNameAfterRemoval -and $CreatedContact.Name -ne $PreferredContactName) {
                            $PendingNameNormalizations.Add([PSCustomObject] @{
                                    Identity            = if ($CreatedContact.MailContact.Identity) { $CreatedContact.MailContact.Identity } else { $Source.PrimarySmtpAddress }
                                    CurrentName         = $CreatedContact.Name
                                    PreferredName       = $PreferredContactName
                                    ConflictingIdentity = $ConflictingContactAddress
                                })
                        }
                        $CountAdd++
                    }
                }
            }
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
                    if ($Contact.Name -and $ReservedContactNames) {
                        $null = $ReservedContactNames.Remove([string] $Contact.Name)
                    }
                    if ($Contact.Name -and $ReservedContactNameOwners) {
                        $ReservedContactNameOwners.Remove([string] $Contact.Name)
                    }
                    $CountRemove++
                    $null = $RemovedContacts.Add([string] $Contact.PrimarySmtpAddress)
                } catch {
                    Write-Color -Text "[e] ", "Failed to remove contact. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
                }

            }
        }
    }
    foreach ($PendingNameNormalization in $PendingNameNormalizations) {
        if (-not $RemovedContacts.Contains($PendingNameNormalization.ConflictingIdentity)) {
            continue
        }
        $NormalizedName = $PendingNameNormalization.PreferredName
        $RemovedCurrentName = $false
        if ($ReservedContactNames) {
            $RemovedCurrentName = $ReservedContactNames.Remove($PendingNameNormalization.CurrentName)
            $Index = 2
            while ($ReservedContactNames.Contains($NormalizedName)) {
                $NormalizedName = "$($PendingNameNormalization.PreferredName)-$Index"
                $Index++
            }
        }
        if ($NormalizedName -eq $PendingNameNormalization.CurrentName) {
            if ($ReservedContactNames -and $RemovedCurrentName) {
                $null = $ReservedContactNames.Add($PendingNameNormalization.CurrentName)
            }
            continue
        }
        Write-Color -Text "[*] ", "Normalizing Exchange Name for ", $PendingNameNormalization.Identity, " to ", $NormalizedName -Color Yellow, Green, DarkCyan, White, Cyan
        try {
            Set-MailContact -Identity $PendingNameNormalization.Identity -Name $NormalizedName -WhatIf:$WhatIfPreference -ErrorAction Stop
            if ($ReservedContactNames) {
                $null = $ReservedContactNames.Add($NormalizedName)
            }
            if ($ReservedContactNameOwners) {
                $ReservedContactNameOwners.Remove($PendingNameNormalization.CurrentName)
                $ReservedContactNameOwners[$NormalizedName] = [string] $PendingNameNormalization.Identity
            }
        } catch {
            if ($ReservedContactNames -and $RemovedCurrentName) {
                $null = $ReservedContactNames.Add($PendingNameNormalization.CurrentName)
            }
            Write-Color -Text "[e] ", "Failed to normalize Exchange Name. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
        }
    }
    Write-Color -Text "[i] ", "Synchronization summary: ", $CountAdd, " added, ", $CountUpdate, " updated, ", $CountRemove, " removed" -Color Yellow, White, Cyan, White, Cyan, White, Cyan, White, Cyan
    $EndTimeLog = Stop-TimeLog -Time $StartTimeLog
    Write-Color -Text "[i] ", "Finished synchronization of ", $SourceObjects.Count, " objects. ", "Time: ", $EndTimeLog -Color Yellow, White, Cyan, White, Yellow, Cyan
}
