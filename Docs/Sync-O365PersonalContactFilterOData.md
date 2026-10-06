---
external help file: O365Synchronizer-help.xml
Module Name: O365Synchronizer
online version: https://github.com/EvotecIT/O365Synchronizer
schema: 2.0.0
---
# Sync-O365PersonalContactFilterOData
## SYNOPSIS
Provides a way to prefilter users with Microsoft Graph OData.

## SYNTAX
### __AllParameterSets
```powershell
Sync-O365PersonalContactFilterOData [-Filter] <string> [[-ConsistencyLevel] <string>] [[-CountVariable] <string>] [[-PageSize] <int>] [<CommonParameters>]
```

## DESCRIPTION
Provides a way to prefilter users with Microsoft Graph OData.
The filter is applied to Get-MgUser and affects only Member/Guest queries.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -Filter {
    Sync-O365PersonalContactFilterOData -Filter "onPremisesExtensionAttributes/extensionAttribute5 eq 'MYFILTER'" -ConsistencyLevel eventual -CountVariable userCount -PageSize 999
}
```


### EXAMPLE 2
```powershell
PS > Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -Filter {
    Sync-O365PersonalContactFilterOData -Filter "startsWith(displayName,'Test')"
}
```


## PARAMETERS

### -ConsistencyLevel
Consistency level used by Microsoft Graph for advanced queries.

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

### -CountVariable
Count variable name for advanced queries.

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

### -Filter
OData filter string to apply to Get-MgUser.

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

### -PageSize
Page size used by Microsoft Graph when paging results.

```yaml
Type: Int32
Parameter Sets: __AllParameterSets
Aliases: None
Possible values:

Required: False
Position: 3
Default value: 0
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
