---
external help file: O365Synchronizer-help.xml
Module Name: O365Synchronizer
online version: https://github.com/EvotecIT/O365Synchronizer
schema: 2.0.0
---
# Sync-O365PersonalContact
## SYNOPSIS
Synchronizes Users, Contacts and Guests to Personal Contacts of given user.

## SYNTAX
### __AllParameterSets
```powershell
Sync-O365PersonalContact [[-Filter] <scriptblock>] [[-UserId] <string[]>] [[-MemberTypes] <string[]>] [[-GuidPrefix] <string>] [[-FolderName] <string>] [[-IncludeExternalUsers] <string[]>] [[-Category] <string[]>] [-RequireEmailAddress] [-DoNotRequireAccountEnabled] [-DoNotRequireAssignedLicenses] [-ExcludeHiddenFromAddressList] [-HiddenAddressListSource <HiddenAddressListSource>] [-NicknameSource <string>] [-PassThru] [-LogStream <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Synchronizes Users, Contacts and Guests to Personal Contacts of given user.
Includes Department and Manager fields when available.
When Category is provided, assigns those categories to synchronized contacts.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Sync-O365PersonalContact -UserId 'przemyslaw.klys@test.pl' -Verbose -MemberTypes 'Contact', 'Member' -WhatIf
```


### EXAMPLE 2
```powershell
PS > Sync-O365PersonalContact -UserId 'przemyslaw.klys@evotec.pl' -MemberTypes 'Contact', 'Member' -GuidPrefix 'O365Synchronizer' -PassThru {
    Sync-O365PersonalContactFilter -Type Include -Property 'CompanyName' -Value 'Evotec*','Ziomek*' -Operator 'like'
    Sync-O365PersonalContactFilterGroup -Type Include -GroupID 'e7772951-4b0e-4f10-8f38-eae9b8f55962'
} -FolderName 'O365Sync' | Format-Table
```


### EXAMPLE 3
```powershell
PS > Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member', 'Guest' -IncludeExternalUsers 'Guest', 'ExtUPN' -Verbose
```


### EXAMPLE 4
```powershell
PS > # opt-in, best-effort Graph fallback only
Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -ExcludeHiddenFromAddressList -HiddenAddressListSource Graph -Verbose
```


### EXAMPLE 5
```powershell
PS > # recommended authoritative filtering via Exchange Online (Connect-ExchangeOnline first)
Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member', 'Contact' -ExcludeHiddenFromAddressList -HiddenAddressListSource Exchange -Verbose
```


### EXAMPLE 6
```powershell
PS > Sync-O365PersonalContact -UserId 'user@contoso.com' -FolderName 'O365Sync' -RequireEmailAddress -Verbose
```


### EXAMPLE 7
```powershell
PS > Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -Category 'Friends', 'Work' -Verbose
```


### EXAMPLE 8
```powershell
PS > # preserve the legacy Exchange mail alias in the Nickname field
Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -NicknameSource MailNickname -Verbose
```


### EXAMPLE 9
```powershell
PS > # clear categories assigned by sync
Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -Category @() -Verbose
```


### EXAMPLE 10
```powershell
PS > Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -PassThru {
    Sync-O365PersonalContactFilterOData -Filter "onPremisesExtensionAttributes/extensionAttribute5 eq 'MYFILTER'" -ConsistencyLevel eventual -CountVariable userCount -PageSize 999
}
```


### EXAMPLE 11
```powershell
PS > Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -PassThru {
    Sync-O365PersonalContactFilter -Type Include -Property 'OnPremisesExtensionAttributes.ExtensionAttribute5' -Value @('MYFILTER') -Operator 'Equal'
}
```


## PARAMETERS

### -Category
Categories assigned to synchronized personal contacts.

```yaml
Type: String[]
Parameter Sets: __AllParameterSets
Aliases: Categories
Possible values:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotRequireAccountEnabled
Do not require account to be enabled. By default account must be enabled, otherwise it will be skipped.

```yaml
Type: SwitchParameter
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotRequireAssignedLicenses
Do not require assigned licenses. By default user must have assigned licenses, otherwise it will be skipped.
The licenses are checked by looking at AssignedLicenses property of the user, and not the actual license types.

```yaml
Type: SwitchParameter
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeHiddenFromAddressList
Best-effort exclusion for users whose Graph showInAddressList property is explicitly set to false.
Microsoft documents showInAddressList as "Do not use in Microsoft Graph", so
Graph mode should be treated as an opt-in compatibility fallback only.
Users are left in scope when showInAddressList is null, missing, or not returned by Graph.
With HiddenAddressListSource Exchange, Exchange Online is used instead and
both users and contacts can be filtered when Exchange reports the recipient
as hidden from the address list.

```yaml
Type: SwitchParameter
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Filters to apply to users. It can be used to filter out users that you don't want to synchronize.
You should use Sync-O365PersonalContactFilter, Sync-O365PersonalContactFilterGroup, or Sync-O365PersonalContactFilterOData to create filter(s).

```yaml
Type: ScriptBlock
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FolderName
Name of the folder to synchronize contacts to. If not set it will synchronize contacts to the main folder.

```yaml
Type: String
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GuidPrefix
Prefix of the GUID that is used to identify contacts that were synchronized by O365Synchronizer.
By default no prefix is used, meaning GUID of the user will be used as File, As property of the contact.

```yaml
Type: String
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HiddenAddressListSource
Controls whether hidden-address-list filtering uses Microsoft Graph or
Exchange Online as the source of truth. Graph is the default only to preserve
the current auth model for callers that explicitly opt into this fallback.
Exchange is the recommended authoritative source and requires an active
Exchange session.

```yaml
Type: HiddenAddressListSource
Parameter Sets: __AllParameterSets
Aliases: None
Possible values: Graph, Exchange

Required: False
Position: named
Default value: Graph
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeExternalUsers
Allows unlicensed external users to be included when assigned licenses are required.
Use 'Guest' to include users with UserType = Guest.
Use 'ExtUPN' to include users with #EXT# in UserPrincipalName.

```yaml
Type: String[]
Parameter Sets: __AllParameterSets
Aliases: None
Possible values: Guest, ExtUPN

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogStream
Routes messages to Host (default), Output, Verbose, or Information for this call.
Use -LogStream Output for Azure Automation without enabling verbose job logging.
Output adds plain log strings to the success stream alongside any returned data.

```yaml
Type: String
Parameter Sets: __AllParameterSets
Aliases: None
Possible values: Host, Output, Verbose, Information

Required: False
Position: named
Default value: Host
Accept pipeline input: False
Accept wildcard characters: False
```

### -MemberTypes
Member types to synchronize. By default it will synchronize only 'Member'. You can also specify 'Guest' and 'Contact'.

```yaml
Type: String[]
Parameter Sets: __AllParameterSets
Aliases: None
Possible values: Member, Guest, Contact

Required: False
Position: 2
Default value: @('Member')
Accept pipeline input: False
Accept wildcard characters: False
```

### -NicknameSource
Directory property written to the personal contact Nickname field.
DisplayName is the default so Outlook shows the GAL display name instead
of the Exchange mail alias. Use MailNickname to preserve legacy behavior.

```yaml
Type: String
Parameter Sets: __AllParameterSets
Aliases: None
Possible values: DisplayName, MailNickname

Required: False
Position: named
Default value: DisplayName
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Specifies the pass thru switch.

```yaml
Type: SwitchParameter
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequireEmailAddress
Sync only users that have email address.

```yaml
Type: SwitchParameter
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserId
Identity of the user to synchronize contacts to. It can be UserID or UserPrincipalName.

```yaml
Type: String[]
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

- `None`

## OUTPUTS

- `None`

## RELATED LINKS

- None
