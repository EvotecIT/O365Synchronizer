---
external help file: O365Synchronizer-help.xml
Module Name: O365Synchronizer
online version: https://github.com/EvotecIT/O365Synchronizer
schema: 2.0.0
---
# Clear-O365PersonalContact
## SYNOPSIS
Removes personal contacts from user on Office 365.

## SYNTAX
### __AllParameterSets
```powershell
Clear-O365PersonalContact [-Identity] <string> [[-GuidPrefix] <string>] [[-FolderName] <string>] [[-LogStream] <string>] [-FolderRemove] [-FullLogging] [-All] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Removes personal contacts from user on Office 365.
By default it will only remove contacts that were synchronized by O365Synchronizer.
If you want to remove all contacts use -All parameter.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -WhatIf
```


### EXAMPLE 2
```powershell
PS > Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -GuidPrefix 'O365' -WhatIf
```


### EXAMPLE 3
```powershell
PS > Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -All -WhatIf
```


### EXAMPLE 4
```powershell
PS > Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -FolderName 'O365Sync' -FolderRemove -WhatIf
```


### EXAMPLE 5
```powershell
PS > Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -GuidPrefix 'O365Synchronizer' -FullLogging -WhatIf
```


## PARAMETERS

### -All
If set it will remove all contacts. By default it will only remove contacts that were synchronized by O365Synchronizer.

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

### -FolderName
Name of the folder to remove contacts from. If not set it will remove contacts from the main folder.

```yaml
Type: String
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FolderRemove
If set it will remove the folder as well, once the contacts are removed.
The folder is removed only when empty; use -All to remove all contacts first if needed.

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

### -FullLogging
If set it will log all actions. By default it will only log actions that meant contact is getting removed or an error happens.

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

### -GuidPrefix
Prefix of the GUID that is used to identify contacts that were synchronized by O365Synchronizer.
By default no prefix is used, meaning GUID of the user will be used as File, As property of the contact.

```yaml
Type: String
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Identity
Identity of the user to remove contacts from.

```yaml
Type: String
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: True
Position: 0
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
Position: 3
Default value: Host
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
