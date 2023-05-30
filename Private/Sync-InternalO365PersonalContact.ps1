function Sync-InternalO365PersonalContact {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [string] $UserId,
        [ValidateSet('Member', 'Guest', 'Contact')][string[]] $MemberTypes,
        [switch] $RequireEmailAddress,
        [string] $GuidPrefix,
        [System.Collections.IDictionary] $ExistingUsers,
        [System.Collections.IDictionary] $ExistingContacts
    )
    $ListActions = [System.Collections.Generic.List[object]]::new()
    # $ToPotentiallyRemove = [System.Collections.Generic.List[object]]::new()
    # foreach ($ContactID in $ExistingContacts.Keys) {
    #     $Contact = $ExistingContacts[$ContactID]
    #     $Entry = $Contact.FileAs
    #     if ($ExistingUsers[$Entry]) {
    #         $User = $ExistingUsers[$Entry]
    #         if ($User.Type -notin $MemberTypes) {
    #             Write-Color -Text "[i] ", "Skipping ", $User.DisplayName, " because they are not a type: ", $($MemberTypes -join ', ') -Color Yellow, White, DarkYellow, White, DarkYellow
    #             $ToPotentiallyRemove.Add($ExistingContacts[$ContactID])
    #         }
    #     } else {
    #         Write-Color -Text "[i] ", "Skipping ", $Contact.DisplayName, " because user does not exist" -Color Yellow, White, DarkYellow, White, DarkYellow
    #         #$ToPotentiallyRemove.Add($ExistingContacts[$ContactID])
    #     }
    # }


    foreach ($UsersInternalID in $ExistingUsers.Keys) {
        $User = $ExistingUsers[$UsersInternalID]
        if ($User.Mail) {
            Write-Color -Text "[i] ", "Processing ", $User.DisplayName, " / ", $User.Mail -Color Yellow, White, Cyan, White, Cyan
        } else {
            Write-Color -Text "[i] ", "Processing ", $User.DisplayName -Color Yellow, White, Cyan
        }
        $Entry = $User.Id
        $Contact = $ExistingContacts[$Entry]

        # lets check if user is a member or guest
        # if ($User.Type -notin $MemberTypes) {
        #     Write-Color -Text "[i] ", "Skipping ", $User.DisplayName, " because they are not a ", $($MemberTypes -join ', ') -Color Yellow, White, DarkYellow, White, DarkYellow
        #     if ($Contact) {
        #         $ToPotentiallyRemove.Add($ExistingContacts[$Entry])
        #     }
        #     continue
        # }
        if ($Contact) {
            # Contact exists, lets check if we need to update it
            $OutputObject = Set-O365InternalContact -UserID $UserId -User $User -Contact $Contact
            $ListActions.Add($OutputObject)
        } else {
            # Contact does not exist, lets create it
            $OutputObject = New-O365InternalContact -UserId $UserId -User $User -GuidPrefix $GuidPrefix -RequireEmailAddress:$RequireEmailAddress
            $ListActions.Add($OutputObject)
        }
    }
    # now lets remove any contacts that are not required or filtered out
    $RemoveActions = Remove-O365InternalContact -ExistingUsers $ExistingUsers -ExistingContacts $ExistingContacts -UserId $UserId
    foreach ($Remove in $RemoveActions) {
        $ListActions.Add($Remove)
    }
    $ListActions
}