function Sync-O365PersonalContact {
    <#
    .SYNOPSIS
    Synchronizes Users, Contacts and Guests to Personal Contacts of given user.

    .DESCRIPTION
    Synchronizes Users, Contacts and Guests to Personal Contacts of given user.
    Includes Department and Manager fields when available.
    When Category is provided, assigns those categories to synchronized contacts.

    .PARAMETER Filter
    Filters to apply to users. It can be used to filter out users that you don't want to synchronize.
    You should use Sync-O365PersonalContactFilter, Sync-O365PersonalContactFilterGroup, or Sync-O365PersonalContactFilterOData to create filter(s).

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

    .PARAMETER IncludeExternalUsers
    Allows unlicensed external users to be included when assigned licenses are required.
    Use 'Guest' to include users with UserType = Guest.
    Use 'ExtUPN' to include users with #EXT# in UserPrincipalName.

    .PARAMETER ExcludeHiddenFromAddressList
    Excludes users whose Graph showInAddressList property is explicitly set to false.
    Users are left in scope when showInAddressList is null or missing.
    This applies only to user objects; Microsoft Graph org contacts do not expose an equivalent property.

    .PARAMETER GuidPrefix
    Prefix of the GUID that is used to identify contacts that were synchronized by O365Synchronizer.
    By default no prefix is used, meaning GUID of the user will be used as File, As property of the contact.

    .PARAMETER FolderName
    Name of the folder to synchronize contacts to. If not set it will synchronize contacts to the main folder.

    .PARAMETER Category
    Categories assigned to synchronized personal contacts.

    .EXAMPLE
    Sync-O365PersonalContact -UserId 'przemyslaw.klys@test.pl' -Verbose -MemberTypes 'Contact', 'Member' -WhatIf

    .EXAMPLE
    Sync-O365PersonalContact -UserId 'przemyslaw.klys@evotec.pl' -MemberTypes 'Contact', 'Member' -GuidPrefix 'O365Synchronizer' -PassThru {
        Sync-O365PersonalContactFilter -Type Include -Property 'CompanyName' -Value 'Evotec*','Ziomek*' -Operator 'like'
        Sync-O365PersonalContactFilterGroup -Type Include -GroupID 'e7772951-4b0e-4f10-8f38-eae9b8f55962'
    } -FolderName 'O365Sync' | Format-Table

    .EXAMPLE
    Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member', 'Guest' -IncludeExternalUsers 'Guest', 'ExtUPN' -Verbose

    .EXAMPLE
    Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -ExcludeHiddenFromAddressList -Verbose

    .EXAMPLE
    Sync-O365PersonalContact -UserId 'user@contoso.com' -FolderName 'O365Sync' -RequireEmailAddress -Verbose

    .EXAMPLE
    Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -Category 'Friends', 'Work' -Verbose

    .EXAMPLE
    # clear categories assigned by sync
    Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -Category @() -Verbose

    .EXAMPLE
    Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -PassThru {
        Sync-O365PersonalContactFilterOData -Filter "onPremisesExtensionAttributes/extensionAttribute5 eq 'MYFILTER'" -ConsistencyLevel eventual -CountVariable userCount -PageSize 999
    }

    .EXAMPLE
    Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -PassThru {
        Sync-O365PersonalContactFilter -Type Include -Property 'OnPremisesExtensionAttributes.ExtensionAttribute5' -Value @('MYFILTER') -Operator 'Equal'
    }

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
        [string] $FolderName,
        [switch] $DoNotRequireAccountEnabled,
        [switch] $DoNotRequireAssignedLicenses,
        [ValidateSet('Guest', 'ExtUPN')][string[]] $IncludeExternalUsers,
        [switch] $ExcludeHiddenFromAddressList,
        [Alias('Categories')][string[]] $Category,
        [switch] $PassThru
    )

    Initialize-DefaultValuesO365
    if ($ExcludeHiddenFromAddressList -and $MemberTypes -contains 'Contact') {
        Write-Warning 'ExcludeHiddenFromAddressList applies only to user objects. Microsoft Graph org contacts do not expose an equivalent hidden-from-address-list property.'
    }

    # Lets get all users and cache them
    $getO365ExistingMembersSplat = @{
        MemberTypes             = $MemberTypes
        RequireAccountEnabled   = -not $DoNotRequireAccountEnabled.IsPresent
        RequireAssignedLicenses = -not $DoNotRequireAssignedLicenses.IsPresent
        UserProvidedFilter      = $Filter
    }
    if ($PSBoundParameters.ContainsKey('IncludeExternalUsers')) {
        $getO365ExistingMembersSplat['IncludeExternalUsers'] = $IncludeExternalUsers
    }
    if ($ExcludeHiddenFromAddressList) {
        $getO365ExistingMembersSplat['ExcludeHiddenFromAddressList'] = $true
    }

    $ExistingUsers = Get-O365ExistingMembers @getO365ExistingMembersSplat
    if ($ExistingUsers -eq $false -or $ExistingUsers -is [Array]) {
        return
    }

    foreach ($User in $UserId) {
        $FolderInformation = Initialize-FolderName -UserId $User -FolderName $FolderName
        if ($FolderInformation -eq $false) {
            return
        }
        # Lets get all contacts of given person and cache them
        $ExistingContacts = Get-O365ExistingUserContacts -UserID $User -GuidPrefix $GuidPrefix -FolderName $FolderName
        if ($ExistingContacts -eq $false) {
            continue
        }
        $syncInternalSplat = @{
            FolderInformation  = $FolderInformation
            UserId             = $User
            ExistingUsers      = $ExistingUsers
            ExistingContacts   = $ExistingContacts
            MemberTypes        = $MemberTypes
            RequireEmailAddress = $RequireEmailAddress.IsPresent
            GuidPrefix         = $GuidPrefix
            WhatIf             = $WhatIfPreference
        }
        if ($PSBoundParameters.ContainsKey('Category')) {
            $syncInternalSplat['Category'] = $Category
        }
        $Actions = Sync-InternalO365PersonalContact @syncInternalSplat
        if ($PassThru) {
            $Actions
        }
    }
}
