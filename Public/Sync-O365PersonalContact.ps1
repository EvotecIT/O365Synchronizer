function Sync-O365PersonalContact {
    <#
    .SYNOPSIS
    Synchronizes Users, Contacts and Guests to Personal Contacts of given user.

    .DESCRIPTION
    Synchronizes Users, Contacts and Guests to Personal Contacts of given user.

    .PARAMETER Filter
    Filters to apply to users. It can be used to filter out users that you don't want to synchronize.
    You should use Sync-O365PersonalContactFilter or/and Sync-O365PersonalContactFilterGroup to create filter(s).

    .PARAMETER UserId
    Identity of the user to synchronize contacts to. It can be UserID or UserPrincipalName.

    .PARAMETER MemberTypes
    Member types to synchronize. By default it will synchronize only 'Member'. You can also specify 'Guest' and 'Contact'.

    .PARAMETER RequireEmailAddress
    Sync only users that have email address.

    .PARAMETER DoNotRequireAccountEnabled
    Do not require account to be enabled. By default account must be enabled, otherwise it will be skipped.

    .PARAMETER DoNotRequireAssignedLicenses
    Do not require assigned licenses. By default user must have assigned licenses, otherwise it will be skipped.
    The licenses are checked by looking at AssignedLicenses property of the user, and not the actual license types.

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
        [scriptblock] $Filter,
        [string[]] $UserId,
        [ValidateSet('Member', 'Guest', 'Contact')][string[]] $MemberTypes = @('Member'),
        [switch] $RequireEmailAddress,
        [string] $GuidPrefix,
        [switch] $DoNotRequireAccountEnabled,
        [switch] $DoNotRequireAssignedLicenses,
        [switch] $PassThru
    )

    Initialize-DefaultValuesO365

    # Lets get all users and cache them
    $getO365ExistingMembersSplat = @{
        MemberTypes             = $MemberTypes
        RequireAccountEnabled   = -not $DoNotRequireAccountEnabled.IsPresent
        RequireAssignedLicenses = -not $DoNotRequireAssignedLicenses.IsPresent
        UserProvidedFilter      = $Filter
    }

    $ExistingUsers = Get-O365ExistingMembers @getO365ExistingMembersSplat
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