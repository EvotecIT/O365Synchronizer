---
external help file: O365Synchronizer-help.xml
Module Name: O365Synchronizer
online version:
schema: 2.0.0
---

# Sync-O365Contact

## SYNOPSIS
Synchronize contacts between source and target Office 365 tenant.

## SYNTAX

```
Sync-O365Contact [-SourceObjects] <Array> [[-Domains] <Array>] [-SkipAdd] [-SkipUpdate] [-SkipRemove] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Synchronize contacts between source and target Office 365 tenant.
Get users from source tenant using Get-MgUser (Microsoft Graph) and provide them as source objects.
You can specify domains to synchronize.
If you don't specify domains, it will use all domains from source objects.
During synchronization new contacts will be created matching given domains in target tenant on Exchange Online.
If contact already exists, it will be updated if needed, even if it wasn't synchronized by this module.
It will asses whether it needs to add/update/remove contacts based on provided domain names from source objects.

## EXAMPLES

### EXAMPLE 1
```
An example
```

## PARAMETERS

### -SourceObjects
Source objects to synchronize.
You can use Get-MgUser to get users from Microsoft Graph and provide them as source objects.
Any filtering you apply to them is valid and doesn't have to be 1:1 conversion.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domains
Domains to synchronize.
If not specified, it will use all domains from source objects.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipAdd
Disable the adding of new contacts functionality.
This is useful if you want to only update existing contacts or remove non-existing contacts.

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

### -SkipUpdate
Disable the updating of existing contacts functionality.
This is useful if you want to only add new contacts or remove non-existing contacts.

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

### -SkipRemove
Disable the removing of non-existing contacts functionality.
This is useful if you want to only add new contacts or update existing contacts.

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
