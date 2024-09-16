function Sync-InternalO365PersonalContact {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER UserId
    Parameter description

    .PARAMETER MemberTypes
    Parameter description

    .PARAMETER RequireEmailAddress
    Parameter description

    .PARAMETER GuidPrefix
    Parameter description

    .PARAMETER ExistingUsers
    Users and contacts in GAL that will be synchronized to user's personal contacts

    .PARAMETER ExistingContacts
    Existing contacts in user's personal contacts

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
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