function Sync-O365PersonalContact {
    <#
    .SYNOPSIS
    Synchronizes Users, Contacts and Guests to Personal Contacts of given user.

    .DESCRIPTION
    Synchronizes Users, Contacts and Guests to Personal Contacts of given user.

    .PARAMETER UserId
    Identity of the user to synchronize contacts to. It can be UserID or UserPrincipalName.

    .PARAMETER MemberTypes
    Member types to synchronize. By default it will synchronize only 'Member'. You can also specify 'Guest' and 'Contact'.

    .PARAMETER RequireEmailAddress
    Sync only users that have email address.

    .PARAMETER GuidPrefix
    Prefix of the GUID that is used to identify contacts that were synchronized by O365Synchronizer.
    By default no prefix is used, meaning GUID of the user will be used as File, As property of the contact.

    .EXAMPLE
    Sync-O365PersonalContact -UserId 'przemyslaw.klys@test.pl' -Verbose -MemberTypes 'Contact', 'Member' -WhatIf

    .NOTES
    General notes
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string[]] $UserId,
        [ValidateSet('Member', 'Guest', 'Contact')][string[]] $MemberTypes = @('Member'),
        [switch] $RequireEmailAddress,
        [string] $GuidPrefix,
        [switch] $PassThru
    )

    Initialize-DefaultValuesO365

    # Lets get all users and cache them
    $ExistingUsers = Get-O365ExistingMembers -MemberTypes $MemberTypes -RequireAccountEnabled -RequireAssignedLicenses
    if ($ExistingUsers -eq $false -or $ExistingUsers -is [Array]) {
        return
    }

    foreach ($User in $UserId) {
        # Lets get all contacts of given person and cache them
        $ExistingContacts = Get-O365ExistingUserContacts -UserID $User -GuidPrefix $GuidPrefix

        $Actions = Sync-InternalO365PersonalContact -UserId $User -ExistingUsers $ExistingUsers -ExistingContacts $ExistingContacts -MemberTypes $MemberTypes -RequireEmailAddress:$RequireEmailAddress.IsPresent -GuidPrefix $GuidPrefix -WhatIf:$WhatIfPreference
        if ($PassThru) {
            $Actions
        }
    }
}