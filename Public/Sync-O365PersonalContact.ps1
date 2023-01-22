function Sync-O365PersonalContact {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [System.Collections.IDictionary] $Authorization,
        [string] $UserId,
        [ValidateSet('Member', 'Guest')][string[]] $MemberTypes = @('Member', 'Guest'),
        [switch] $RequireEmailAddress

    )
    $PropertiesUsers = @(
        'DisplayName'
        'GivenName'
        'Surname'
        'Mail'
        'MailNickname'
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

    # Lets get all users and cache them
    $ExistingContacts = [ordered] @{}
    $ExistingUsers = [ordered] @{}
    $Users = Get-MgUser -Property $PropertiesUsers -All | Select-Object $PropertiesUsers
    foreach ($User in $Users) {
        if (-not $User.AccountEnabled) {
            continue
        }
        if ($User.AssignedLicenses.Count -eq 0) {
            continue
        }
        $Entry = $User.Id
        #$Entry = [string]::Concat($User.DisplayName, $User.GivenName, $User.Surname)
        $ExistingUsers[$Entry] = $User
    }

    # Lets get all contacts of given person and cache them
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
        # $Entry = [string]::Concat($Contact.DisplayName, $Contact.GivenName, $Contact.Surname)
        $ExistingContacts[$Entry] = $Contact
    }

    $ToPotentiallyRemove = [System.Collections.Generic.List[object]]::new()
    foreach ($UsersInternalID in $ExistingUsers.Keys) {
        $User = $ExistingUsers[$UsersInternalID]
        #Write-Verbose -Message "Sync-O365PersonalContact - Processing $($User.DisplayName) / $($User.Mail)"
        Write-Color -Text "[i] ", "Processing ", $User.DisplayName, " / ", $User.Mail -Color Yellow, White, Cyan, White, Cyan

        $Entry = $User.Id
        #$Entry = [string]::Concat($User.DisplayName, $User.GivenName, $User.Surname)
        $Contact = $ExistingContacts[$Entry]

        # lets check if user is a member or guest
        if ($User.UserType -notin $MemberTypes) {
            Write-Color -Text "[i] ", "Skipping ", $User.DisplayName, " because they are not a ", $($MemberTypes -join ', ') -Color Yellow, White, DarkYellow, White, DarkYellow
            #Write-Verbose -Message "Skipping $($User.DisplayName) because they are not a $($MemberTypes -join ', ')"
            if ($Contact) {
                $ToPotentiallyRemove.Add($ExistingContacts[$Entry])
            }
            continue
        }

        if ($Contact) {
            $Properties = Compare-UserToContact -User $User -Contact $Contact
            if ($Properties.Update.Count -gt 0) {
                Write-Color -Text "[i] ", "Updating ", $User.DisplayName, " / ", $User.Mail, " properties to update: ", $($Properties.Update -join ', '), " properties to skip: ", $($Properties.Skip -join ', ') -Color Yellow, White, Green, White, Green, White, Green, White, Cyan
                #Write-Verbose -Message "Sync-O365PersonalContact - Updating $($User.DisplayName) / $($User.Mail), properties to update: $($Properties.Update), properties to skip: $($Properties.Skip)"
                Set-O365Contact -UserID $UserId -User $User -Contact $Contact -Properties $Properties.Update
            }
        } else {
            if ($User.Mail) {
                #Write-Verbose -Message "Sync-O365PersonalContact - Creating $($User.DisplayName) / $($User.Mail)"
                Write-Color -Text "[+] ", "Creating ", $User.DisplayName, " / ", $User.Mail -Color Yellow, White, Green, White, Green
                $CreatedContact = New-MgUserContact -FileAs $User.Id -UserId $UserId -NickName $User.MailNickname -DisplayName $User.DisplayName -GivenName $User.GivenName -Surname $User.Surname -EmailAddresses @(@{Address = $User.Mail; Name = $User.MailNickname; }) -MobilePhone $User.MobilePhone -HomePhone $User.HomePhone -BusinessPhones $User.BusinessPhones
                if ($CreatedContact) {

                }
            } else {
                #Write-Verbose -Message "Skipping $($User.DisplayName) because they have no email address"
            }
        }
    }
    foreach ($Contact in $ToPotentiallyRemove) {
        Write-Color -Text "[x] ", "Removing (type mismatch)", $Contact.DisplayName -Color Yellow, White, Red, White, Red
        #Write-Verbose -Message "Sync-O365PersonalContact - Removing (type removal) $($Contact.DisplayName)"
        Remove-MgUserContact -UserId $UserId -ContactId $Contact.Id
    }
    foreach ($ContactID in $ExistingContacts[$Entry].Keys) {
        $Contact = $ExistingContacts[$ContactID]
        $Entry = $Contact.FileAs
        #$Entry = [string]::Concat($Contact.DisplayName, $Contact.GivenName, $Contact.Surname)
        if ($ExistingUsers[$Entry]) {

        } else {
            #Write-Verbose -Message "Sync-O365PersonalContact - Removing $($Contact.DisplayName)"
            Write-Color -Text "[x] ", "Removing ", $Contact.DisplayName -Color Yellow, White, Red, White, Red
            Remove-MgUserContact -UserId $UserId -ContactId $Contact.Id #-WhatIf
        }
    }
}