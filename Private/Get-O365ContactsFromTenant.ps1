function Get-O365ContactsFromTenant {
    <#
    .SYNOPSIS
    Retrieves Exchange contacts for configured domains.

    .DESCRIPTION
    Loads contacts and mail contacts from Exchange and returns a cache
    keyed by primary SMTP address for the provided domains.

    .PARAMETER Domains
    Allowed SMTP domains to include.
    #>
    [cmdletbinding()]
    param(
        [Array] $Domains
    )
    $CurrentContactsCache = [ordered]@{}
    $ReservedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $ReservedDisplayNames = @{}
    Write-Color -Text "[>] ", "Getting current contacts" -Color Yellow, White, Cyan
    try {
        $CurrentContacts = Get-Contact -ResultSize Unlimited -ErrorAction Stop
    } catch {
        Write-Color -Text "[e] ", "Failed to get current contacts. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
        return
    }

    Write-Color -Text "[>] ", "Getting current mail contacts (improving dataset)" -Color Yellow, White, Cyan
    try {
        $CurrentMailContacts = Get-MailContact -ResultSize Unlimited -ErrorAction Stop
    } catch {
        Write-Color -Text "[e] ", "Failed to get current contacts. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
        return
    }

    Write-Color -Text "[i] ", "Preparing ", $CurrentContacts.Count, " (", "Mail contacts: ", $CurrentMailContacts.Count , ")", " contacts for comparison" -Color Yellow, White, Cyan, White, white, Cyan, White, Yellow

    # We need to do this because Get-MailContact doesn't have all data
    foreach ($Contact in $CurrentMailContacts) {
        if ($Contact.Name) {
            $null = $ReservedNames.Add([string] $Contact.Name)
        }
        if ($Contact.DisplayName) {
            if ($ReservedDisplayNames.Contains($Contact.DisplayName)) {
                $ReservedDisplayNames[$Contact.DisplayName]++
            } else {
                $ReservedDisplayNames[$Contact.DisplayName] = 1
            }
        }
        $Found = $false
        foreach ($Domain in $Domains) {
            if ($Contact.PrimarySmtpAddress -notlike "*@$Domain") {
                continue
            } else {
                $Found = $true
            }
        }
        if ($Found) {
            $CurrentContactsCache[$Contact.PrimarySmtpAddress] = [ordered] @{
                MailContact = $Contact
                Contact     = $null
            }
        }
    }
    # We need to do this because Get-Contact doesn't have all data
    foreach ($Contact in $CurrentContacts) {
        if ($Contact.Name) {
            $null = $ReservedNames.Add([string] $Contact.Name)
        }
        if ($Contact.DisplayName) {
            if ($ReservedDisplayNames.Contains($Contact.DisplayName)) {
                $ReservedDisplayNames[$Contact.DisplayName]++
            } else {
                $ReservedDisplayNames[$Contact.DisplayName] = 1
            }
        }
        if ($CurrentContactsCache[$Contact.WindowsEmailAddress]) {
            $CurrentContactsCache[$Contact.WindowsEmailAddress].Contact = $Contact
        } else {
            # shouldn't really happen
        }
    }
    [PSCustomObject] @{
        ContactsCache         = $CurrentContactsCache
        ReservedNames         = $ReservedNames
        ReservedDisplayNames  = $ReservedDisplayNames
    }
}
