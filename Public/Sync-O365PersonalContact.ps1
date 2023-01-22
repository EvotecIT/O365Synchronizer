function Sync-O365PersonalContact {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [System.Collections.IDictionary] $Authorization,
        [string] $UserId,
        [ValidateSet('Member', 'Guest', 'Contact')][string[]] $MemberTypes = @('Member'),
        [switch] $RequireEmailAddress

    )
    $PropertiesUsers = @(
        'DisplayName'
        'GivenName'
        'Surname'
        'Mail'
        'Nickname'
        'MobilePhone'
        'HomePhone'
        'BusinessPhones'
        'UserPrincipalName'
        'Id',
        'UserType'
        'EmployeeType'
        'AccountEnabled'
        'CreatedDateTime'
        'AssignedLicenses'
    )

    $PropertiesContacts = @(
        'DisplayName'
        'GivenName'
        'Surname'
        'Mail'
        'JobTitle'
        'MailNickname'
        'Phones'
        'UserPrincipalName'
        'Id',
        'CompanyName'
        'OnPremisesSyncEnabled'
        'Addresses'
    )

    # Lets get all users and cache them
    $ExistingUsers = [ordered] @{}
    if ($MemberTypes -contains 'Member' -or $MemberTypes -contains 'Guest') {
        $Users = Get-MgUser -Property $PropertiesUsers -All #| Select-Object $PropertiesUsers
        foreach ($User in $Users) {
            if (-not $User.AccountEnabled) {
                continue
            }
            if ($User.AssignedLicenses.Count -eq 0) {
                continue
            }
            Add-Member -MemberType NoteProperty -Name 'Type' -Value $User.UserType -InputObject $User
            $Entry = $User.Id
            $ExistingUsers[$Entry] = $User
        }
    }
    if ($MemberTypes -contains 'Contact') {
        $Users = Get-MgContact -Property $PropertiesContacts -All #| Select-Object $PropertiesContacts
        foreach ($User in $Users) {
            $Entry = $User.Id
            Add-Member -MemberType NoteProperty -Name 'Type' -Value 'Contact' -InputObject $User
            $ExistingUsers[$Entry] = $User
        }
    }

    # Lets get all contacts of given person and cache them
    $ExistingContacts = [ordered] @{}
    $CurrentContacts = Get-MgUserContact -UserId $UserId -All
    foreach ($Contact in $CurrentContacts) {
        if (-not $Contact.FileAs) {
            continue
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

    $ToPotentiallyRemove = [System.Collections.Generic.List[object]]::new()
    foreach ($UsersInternalID in $ExistingUsers.Keys) {
        $User = $ExistingUsers[$UsersInternalID]
        #Write-Verbose -Message "Sync-O365PersonalContact - Processing $($User.DisplayName) / $($User.Mail)"
        Write-Color -Text "[i] ", "Processing ", $User.DisplayName, " / ", $User.Mail -Color Yellow, White, Cyan, White, Cyan

        $Entry = $User.Id
        #$Entry = [string]::Concat($User.DisplayName, $User.GivenName, $User.Surname)
        $Contact = $ExistingContacts[$Entry]

        # lets check if user is a member or guest
        if ($User.Type -notin $MemberTypes) {
            Write-Color -Text "[i] ", "Skipping ", $User.DisplayName, " because they are not a ", $($MemberTypes -join ', ') -Color Yellow, White, DarkYellow, White, DarkYellow
            #Write-Verbose -Message "Skipping $($User.DisplayName) because they are not a $($MemberTypes -join ', ')"
            if ($Contact) {
                $ToPotentiallyRemove.Add($ExistingContacts[$Entry])
            }
            continue
        }

        if ($Contact) {
            $Properties = Compare-UserToContact -ExistingContact $User -Contact $Contact
            if ($Properties.Update.Count -gt 0) {
                Write-Color -Text "[i] ", "Updating ", $User.DisplayName, " / ", $User.Mail, " properties to update: ", $($Properties.Update -join ', '), " properties to skip: ", $($Properties.Skip -join ', ') -Color Yellow, White, Green, White, Green, White, Green, White, Cyan
                #Write-Verbose -Message "Sync-O365PersonalContact - Updating $($User.DisplayName) / $($User.Mail), properties to update: $($Properties.Update), properties to skip: $($Properties.Skip)"
                Set-O365Contact -UserID $UserId -User $User -Contact $Contact -Properties $Properties.Update
            }
        } else {
            if ($User.Mail) {
                #Write-Verbose -Message "Sync-O365PersonalContact - Creating $($User.DisplayName) / $($User.Mail)"
                Write-Color -Text "[+] ", "Creating ", $User.DisplayName, " / ", $User.Mail -Color Yellow, White, Green, White, Green

                $newMgUserContactSplat = @{
                    FileAs         = $User.Id
                    UserId         = $UserId
                    NickName       = $User.MailNickname
                    DisplayName    = $User.DisplayName
                    GivenName      = $User.GivenName
                    Surname        = $User.Surname
                    EmailAddresses = @(
                        @{
                            Address = $User.Mail;
                            Name    = $User.MailNickname;
                        }
                    )
                    MobilePhone    = $User.MobilePhone
                    HomePhones     = $User.HomePhone
                    BusinessPhones = $User.BusinessPhones
                    WhatIf         = $WhatIfPreference
                }
                Remove-EmptyValue -Hashtable $newMgUserContactSplat
                $null = New-MgUserContact @newMgUserContactSplat
                #if ($CreatedContact) {
                #Write-Color -Text "[i] ", "Created ", $CreatedContact.DisplayName, " / ", $CreatedContact.Mail -Color Yellow, White, Green, White, Green
                #}
            } else {
                #Write-Verbose -Message "Skipping $($User.DisplayName) because they have no email address"
            }
        }
    }
    foreach ($Contact in $ToPotentiallyRemove) {
        Write-Color -Text "[x] ", "Removing (filtered out) ", $Contact.DisplayName -Color Yellow, White, Red, White, Red
        #Write-Verbose -Message "Sync-O365PersonalContact - Removing (type removal) $($Contact.DisplayName)"
        Remove-MgUserContact -UserId $UserId -ContactId $Contact.Id -WhatIf:$WhatIfPreference
    }
    foreach ($ContactID in $ExistingContacts[$Entry].Keys) {
        $Contact = $ExistingContacts[$ContactID]
        $Entry = $Contact.FileAs
        #$Entry = [string]::Concat($Contact.DisplayName, $Contact.GivenName, $Contact.Surname)
        if ($ExistingUsers[$Entry]) {

        } else {
            #Write-Verbose -Message "Sync-O365PersonalContact - Removing $($Contact.DisplayName)"
            Write-Color -Text "[x] ", "Removing (not required) ", $Contact.DisplayName -Color Yellow, White, Red, White, Red
            Remove-MgUserContact -UserId $UserId -ContactId $Contact.Id -WhatIf:$WhatIfPreference
        }
    }
}