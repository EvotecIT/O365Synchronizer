function Get-O365ContactsFromTenant {
    [cmdletbinding()]
    param(
        [Array] $Domains
    )
    $CurrentContactsCache = [ordered]@{}
    try {
        $CurrentContacts = Get-Contact -ResultSize Unlimited -ErrorAction Stop
    } catch {
        Write-Color -Text "[e] ", "Failed to get current contacts. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
        return
    }
    try {
        $CurrentMailContacts = Get-MailContact -ResultSize Unlimited -ErrorAction Stop
    } catch {
        Write-Color -Text "[e] ", "Failed to get current contacts. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
        return
    }

    Write-Color -Text "[i] ", "Preparing ", $CurrentContacts.Count, " (", "Mail contacts: ", $CurrentMailContacts.Count , ")"," contacts for comparison" -Color Yellow, White, Cyan, White, white, Cyan, White, Yellow

    # We need to do this because Get-MailContact doesn't have all data
    foreach ($Contact in $CurrentMailContacts) {
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
        if ($CurrentContactsCache[$Contact.WindowsEmailAddress]) {
            $CurrentContactsCache[$Contact.WindowsEmailAddress].Contact = $Contact
        } else {
            # shouldn't really happen
        }
    }
    $CurrentContactsCache
}