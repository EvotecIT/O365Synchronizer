function Get-O365ExistingUserContacts {
    [cmdletbinding()]
    param(
        [string] $UserID,
        [string] $GuidPrefix
    )
    # Lets get all contacts of given person and cache them
    $ExistingContacts = [ordered] @{}
    $CurrentContacts = Get-MgUserContact -UserId $UserId -All
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