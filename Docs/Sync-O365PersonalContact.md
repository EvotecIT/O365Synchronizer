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
Sync-O365PersonalContact [[-UserId] <String[]>] [[-MemberTypes] <String[]>] [-RequireEmailAddress]
 [[-GuidPrefix] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Synchronizes Users, Contacts and Guests to Personal Contacts of given user.

## EXAMPLES

### EXAMPLE 1
```
Sync-O365PersonalContact -UserId 'przemyslaw.klys@test.pl' -Verbose -MemberTypes 'Contact', 'Member' -WhatIf
```

## PARAMETERS

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
