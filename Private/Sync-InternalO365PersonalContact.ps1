function Sync-InternalO365PersonalContact {
    <#
    .SYNOPSIS
    Synchronizes personal contacts for a single mailbox.

    .DESCRIPTION
    Creates, updates, and removes personal contacts based on the
    provided GAL users/contacts and existing mailbox contacts.

    .PARAMETER UserId
    User mailbox identifier to synchronize.

    .PARAMETER MemberTypes
    Member types included in synchronization (Member/Guest/Contact).

    .PARAMETER RequireEmailAddress
    When set, skips users without an email address.

    .PARAMETER GuidPrefix
    Optional prefix used to identify synchronized contacts.

    .PARAMETER FolderInformation
    Folder metadata for the target contact folder.

    .PARAMETER ExistingUsers
    Users and contacts from GAL used as sync sources.

    .PARAMETER ExistingContacts
    Existing personal contacts from the mailbox.
    #>
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [string] $UserId,
        [ValidateSet('Member', 'Guest', 'Contact')][string[]] $MemberTypes,
        [switch] $RequireEmailAddress,
        [string] $GuidPrefix,
        [object] $FolderInformation,
        [System.Collections.IDictionary] $ExistingUsers,
        [System.Collections.IDictionary] $ExistingContacts
    )
    $ListActions = [System.Collections.Generic.List[object]]::new()
    foreach ($UsersInternalID in $ExistingUsers.Keys) {
        $User = $ExistingUsers[$UsersInternalID]
        if ($User.Mail) {
            Write-Color -Text "[i] ", "Processing ", $User.DisplayName, " / ", $User.Mail -Color Yellow, White, Cyan, White, Cyan
        } else {
            Write-Color -Text "[i] ", "Processing ", $User.DisplayName -Color Yellow, White, Cyan
        }
        $Entry = $User.Id
        $Contact = $ExistingContacts[$Entry]

        if ($Contact) {
            # Contact exists, lets check if we need to update it
            $OutputObject = Set-O365InternalContact -UserID $UserId -User $User -Contact $Contact
            $ListActions.Add($OutputObject)
        } else {
            # Contact does not exist, lets create it
            $OutputObject = New-O365InternalContact -UserId $UserId -User $User -GuidPrefix $GuidPrefix -RequireEmailAddress:$RequireEmailAddress -FolderInformation $FolderInformation
            $ListActions.Add($OutputObject)
        }
    }
    # now lets remove any contacts that are not required or filtered out, folder name is not needed here
    $RemoveActions = Remove-O365InternalContact -ExistingUsers $ExistingUsers -ExistingContacts $ExistingContacts -UserId $UserId
    foreach ($Remove in $RemoveActions) {
        $ListActions.Add($Remove)
    }
    $ListActions
}
