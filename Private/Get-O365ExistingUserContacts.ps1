function Get-O365ExistingUserContacts {
    [cmdletbinding()]
    param(
        [string] $UserID,
        [string] $GuidPrefix,
        [string] $FolderName
    )
    # Lets get all contacts of given person and cache them
    $ExistingContacts = [ordered] @{}
    if ($FolderName) {
        try {
            $CurrentContactsFolder = Get-MgUserContactFolder -UserId $UserId -Filter "DisplayName eq '$FolderName'" -ErrorAction Stop -All
        } catch {
            Write-Color -Text "[!] ", "Getting user folder ", $FolderName, " failed for ", $UserId, ". Error: ", $_.Exception.Message -Color Red, White, Red, White
            return $false
        }
        if (-not $CurrentContactsFolder) {
            Write-Color -Text "[!] ", "User folder ", $FolderName, " not found for ", $UserId -Color Yellow, Yellow, Red, Yellow, Red
            return $false
        }
        try {
            $CurrentContacts = Get-MgUserContactFolderContact -ContactFolderId $CurrentContactsFolder.Id -UserId $UserId -ErrorAction Stop -All
        } catch {
            Write-Color -Text "[!] ", "Getting user contacts for ", $UserId, " failed. Error: ", $_.Exception.Message -Color Red, White, Red
            return $false
        }
    } else {
        try {
            $CurrentContacts = Get-MgUserContact -UserId $UserId -All -ErrorAction Stop
        } catch {
            Write-Color -Text "[!] ", "Getting user contacts for ", $UserId, " failed. Error: ", $_.Exception.Message -Color Red, White, Red
            return $false
        }
    }
    foreach ($Contact in $CurrentContacts) {
        if (-not $Contact.FileAs) {
            continue
        }

        if ($GuidPrefix -and -not $Contact.FileAs.StartsWith($GuidPrefix)) {
            continue
        } elseif ($GuidPrefix -and $Contact.FileAs.StartsWith($GuidPrefix)) {
            $Contact.FileAs = $Contact.FileAs.Substring($GuidPrefix.Length)
        }

        $Guid = [guid]::Empty
        $ConversionWorked = [guid]::TryParse($Contact.FileAs, [ref]$Guid)
        if (-not $ConversionWorked) {
            continue
        }

        $Entry = [string]::Concat($Contact.FileAs)
        $ExistingContacts[$Entry] = $Contact
    }

    Write-Color -Text "[i] ", "User ", $UserId, " has ", $CurrentContacts.Count, " contacts, out of which ", $ExistingContacts.Count, " synchronized." -Color Yellow, White, Cyan, White, Cyan, White, Cyan, White
    Write-Color -Text "[i] ", "Users to process: ", $ExistingUsers.Count, " Contacts to process: ", $ExistingContacts.Count -Color Yellow, White, Cyan, White, Cyan
    $ExistingContacts
}