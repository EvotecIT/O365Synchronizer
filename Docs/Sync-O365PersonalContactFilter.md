---
external help file: O365Synchronizer-help.xml
Module Name: O365Synchronizer
online version: https://github.com/EvotecIT/O365Synchronizer
schema: 2.0.0
---
# Sync-O365PersonalContactFilter
## SYNOPSIS
Provides a way to filter out users/contacts based on properties.

## SYNTAX
### __AllParameterSets
```powershell
Sync-O365PersonalContactFilter [-Type] <string> [-Operator] <string> [-Property] <string> [[-Value] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Provides a way to filter out users/contacts based on properties.
Only users/contacts that match the filter will be included/excluded.

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
    Sync-O365PersonalContactFilter -Type Include -Property 'OnPremisesExtensionAttributes.ExtensionAttribute5' -Value @('MYFILTER') -Operator 'Equal'
} | Format-Table
```


## PARAMETERS

### -Operator
Operator to use. It can be 'Equal', 'NotEqual', 'LessThan', 'MoreThan', 'Like'.

```yaml
Type: String
Parameter Sets: __AllParameterSets
Aliases: None
Possible values: Equal, NotEqual, LessThan, MoreThan, Like

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Property
Property to use for comparison. Keep in mind that it has to exists on the object.
You can use dot notation for nested properties (for example, OnPremisesExtensionAttributes.ExtensionAttribute5).

```yaml
Type: String
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: True
Position: 2
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

### -Value
Value to compare against. It can be single value or multiple values.

```yaml
Type: Object
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: 3
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
