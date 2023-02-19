function Sync-PersonalContact {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [string] $UserId,
        [ValidateSet('Member', 'Guest', 'Contact')][string[]] $MemberTypes,
        [switch] $RequireEmailAddress,
        [string] $GuidPrefix,
        [System.Collections.IDictionary] $ExistingUsers,
        [System.Collections.IDictionary] $ExistingContacts
    )
    $ToPotentiallyRemove = [System.Collections.Generic.List[object]]::new()
    foreach ($UsersInternalID in $ExistingUsers.Keys) {
        $User = $ExistingUsers[$UsersInternalID]
        Write-Color -Text "[i] ", "Processing ", $User.DisplayName, " / ", $User.Mail -Color Yellow, White, Cyan, White, Cyan

        $Entry = $User.Id
        $Contact = $ExistingContacts[$Entry]

        # lets check if user is a member or guest
        if ($User.Type -notin $MemberTypes) {
            Write-Color -Text "[i] ", "Skipping ", $User.DisplayName, " because they are not a ", $($MemberTypes -join ', ') -Color Yellow, White, DarkYellow, White, DarkYellow
            if ($Contact) {
                $ToPotentiallyRemove.Add($ExistingContacts[$Entry])
            }
            continue
        }

        if ($Contact) {
            $Properties = Compare-UserToContact -ExistingContact $User -Contact $Contact
            if ($Properties.Update.Count -gt 0) {
                Write-Color -Text "[i] ", "Updating ", $User.DisplayName, " / ", $User.Mail, " properties to update: ", $($Properties.Update -join ', '), " properties to skip: ", $($Properties.Skip -join ', ') -Color Yellow, White, Green, White, Green, White, Green, White, Cyan
                Set-O365Contact -UserID $UserId -User $User -Contact $Contact -Properties $Properties.Update
            }
        } else {
            if ($RequireEmailAddress) {
                if (-not $User.Mail) {
                    #Write-Verbose -Message "Skipping $($User.DisplayName) because they have no email address"
                    continue
                }
            }

            Write-Color -Text "[+] ", "Creating ", $User.DisplayName, " / ", $User.Mail -Color Yellow, White, Green, White, Green
            $newMgUserContactSplat = @{
                FileAs         = "$($GuidPrefix)$($User.Id)"
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
                CompanyName    = $User.CompanyName
                WhatIf         = $WhatIfPreference
                ErrorAction    = 'Stop'
            }
            Remove-EmptyValue -Hashtable $newMgUserContactSplat

            try {
                $null = New-MgUserContact @newMgUserContactSplat
            } catch {
                Write-Color -Text "[!] ", "Failed to create contact for ", $User.DisplayName, " / ", $User.Mail, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
            }
        }
    }
    foreach ($Contact in $ToPotentiallyRemove) {
        Write-Color -Text "[x] ", "Removing (filtered out) ", $Contact.DisplayName -Color Yellow, White, Red, White, Red
        Remove-MgUserContact -UserId $UserId -ContactId $Contact.Id -WhatIf:$WhatIfPreference
    }
    foreach ($ContactID in $ExistingContacts[$Entry].Keys) {
        $Contact = $ExistingContacts[$ContactID]
        $Entry = $Contact.FileAs
        if ($ExistingUsers[$Entry]) {

        } else {
            Write-Color -Text "[x] ", "Removing (not required) ", $Contact.DisplayName -Color Yellow, White, Red, White, Red
            Remove-MgUserContact -UserId $UserId -ContactId $Contact.Id -WhatIf:$WhatIfPreference
        }
    }
}