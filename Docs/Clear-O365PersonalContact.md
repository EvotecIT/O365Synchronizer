---
external help file: O365Synchronizer-help.xml
Module Name: O365Synchronizer
online version:
schema: 2.0.0
---

# Clear-O365PersonalContact

## SYNOPSIS
Removes personal contacts from user on Office 365.

## SYNTAX

```
Clear-O365PersonalContact [-Identity] <String> [[-GuidPrefix] <String>] [[-FolderName] <String>]
 [-FolderRemove] [-FullLogging] [-All] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Removes personal contacts from user on Office 365.
By default it will only remove contacts that were synchronized by O365Synchronizer.
If you want to remove all contacts use -All parameter.

## EXAMPLES

### EXAMPLE 1
```
Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -WhatIf
```

### EXAMPLE 2
```
Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -GuidPrefix 'O365' -WhatIf
```

### EXAMPLE 3
```
Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -All -WhatIf
```

### EXAMPLE 4
```
Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -FolderName 'O365Sync' -FolderRemove -WhatIf
```

### EXAMPLE 5
```
Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -GuidPrefix 'O365Synchronizer' -FullLogging -WhatIf
```

## PARAMETERS

### -Identity
Identity of the user to remove contacts from.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
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
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FolderName
Name of the folder to remove contacts from.
If not set it will remove contacts from the main folder.

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

### -FolderRemove
If set it will remove the folder as well, once the contacts are removed.

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

### -FullLogging
If set it will log all actions.
By default it will only log actions that meant contact is getting removed or an error happens.

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

### -All
If set it will remove all contacts.
By default it will only remove contacts that were synchronized by O365Synchronizer.

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
