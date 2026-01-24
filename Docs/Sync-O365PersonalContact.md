---
external help file: O365Synchronizer-help.xml
Module Name: O365Synchronizer
online version:
schema: 2.0.0
---

# Sync-O365PersonalContact

## SYNOPSIS
Synchronizes Users, Contacts and Guests to Personal Contacts of given user.

## SYNTAX

```
Sync-O365PersonalContact [[-Filter] <ScriptBlock>] [[-UserId] <String[]>] [[-MemberTypes] <String[]>]
 [-RequireEmailAddress] [[-GuidPrefix] <String>] [[-FolderName] <String>]
 [-DoNotRequireAccountEnabled] [-DoNotRequireAssignedLicenses] [[-IncludeExternalUsers] <String[]>]
 [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Synchronizes Users, Contacts and Guests to Personal Contacts of given user.
Includes Department and Manager fields when available.

## EXAMPLES

### EXAMPLE 1
```
Sync-O365PersonalContact -UserId 'przemyslaw.klys@test.pl' -Verbose -MemberTypes 'Contact', 'Member' -WhatIf
```

### EXAMPLE 2
```
Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member', 'Guest' -IncludeExternalUsers 'Guest', 'ExtUPN' -Verbose
```

### EXAMPLE 3
```
Sync-O365PersonalContact -UserId 'user@contoso.com' -FolderName 'O365Sync' -RequireEmailAddress -Verbose
```

### EXAMPLE 4
```
Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -PassThru {
    Sync-O365PersonalContactFilterOData -Filter "onPremisesExtensionAttributes/extensionAttribute5 eq 'MYFILTER'" -ConsistencyLevel eventual -CountVariable userCount -PageSize 999
}
```

### EXAMPLE 5
```
Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -PassThru {
    Sync-O365PersonalContactFilter -Type Include -Property 'OnPremisesExtensionAttributes.ExtensionAttribute5' -Value @('MYFILTER') -Operator 'Equal'
}
```

## PARAMETERS

### -Filter
Filters to apply to users.
You should use Sync-O365PersonalContactFilter, Sync-O365PersonalContactFilterGroup, or Sync-O365PersonalContactFilterOData to create filter(s).

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserId
Identity of the user to synchronize contacts to.
It can be UserID or UserPrincipalName.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MemberTypes
Member types to synchronize.
By default it will synchronize only 'Member'.
You can also specify 'Guest' and 'Contact'.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: @('Member')
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequireEmailAddress
Sync only users that have email address.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -GuidPrefix
Prefix of the GUID that is used to identify contacts that were synchronized by O365Synchronizer.
By default no prefix is used, meaning GUID of the user will be used as File, As property of the contact.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FolderName
Name of the folder to synchronize contacts to.
If not set it will synchronize contacts to the main folder.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotRequireAccountEnabled
Do not require account to be enabled.
By default account must be enabled, otherwise it will be skipped.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotRequireAssignedLicenses
Do not require assigned licenses.
By default user must have assigned licenses, otherwise it will be skipped.
The licenses are checked by looking at AssignedLicenses property of the user, and not the actual license types.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeExternalUsers
Allows unlicensed external users to be included when assigned licenses are required.
Use 'Guest' to include users with UserType = Guest.
Use 'ExtUPN' to include users with #EXT# in UserPrincipalName.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Returns actions taken during synchronization.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
General notes

## RELATED LINKS
