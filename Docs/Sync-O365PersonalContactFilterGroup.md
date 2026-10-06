---
external help file: O365Synchronizer-help.xml
Module Name: O365Synchronizer
online version: https://github.com/EvotecIT/O365Synchronizer
schema: 2.0.0
---
# Sync-O365PersonalContactFilterGroup
## SYNOPSIS
Provides a way to filter out users/contacts based on groups.

## SYNTAX
### __AllParameterSets
```powershell
Sync-O365PersonalContactFilterGroup [-Type] <string> [-GroupID] <string[]> [<CommonParameters>]
```

## DESCRIPTION
Provides a way to filter out users/contacts based on groups.
Only users/contacts that are part of the group will be included/excluded.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Sync-O365PersonalContact -UserId 'przemyslaw.klys@test.pl' -Verbose -MemberTypes 'Contact', 'Member' -GuidPrefix 'O365Synchronizer' -WhatIf -PassThru {
    Sync-O365PersonalContactFilter -Type Include -Property 'CompanyName' -Value 'OtherCompany*','Evotec*' -Operator 'like' # filter out on CompanyName
    Sync-O365PersonalContactFilterGroup -Type Include -GroupID 'e7772951-4b0e-4f10-8f38-eae9b8f55962' # filter out on GroupID
} | Format-Table
```


### EXAMPLE 2
```powershell
PS > Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -PassThru {
    Sync-O365PersonalContactFilterGroup -Type Exclude -GroupID '00000000-0000-0000-0000-000000000000'
} | Format-Table
```


## PARAMETERS

### -GroupID
One or multiple GroupID's to filter out users/contacts. Keep in mind that it's not the name of the group, but the actual ID of the group.
Due to performance reasons it's better to use GroupID instead of GroupName.

```yaml
Type: String[]
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
Type of the filter. It can be 'Include' or 'Exclude'.

```yaml
Type: String
Parameter Sets: __AllParameterSets
Aliases: None
Possible values: Include, Exclude

Required: True
Position: 0
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
