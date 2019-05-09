---
external help file: litmos-client-help.xml
Module Name: litmos-client
online version: https://github.com/fletcherg/litmos-client
schema: 2.0.0
---

# Get-LitmosUser

## SYNOPSIS
This function will list Users based on conditions.

## SYNTAX

```
Get-LitmosUser [[-orderBy] <Object>] [[-userid] <String>] [[-search] <String>] [-details] [-all]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Get-LitmosUser -all
```

Will return all users

### EXAMPLE 2
```
Get-LitmosUser -all
```

Will return all users with details

## PARAMETERS

### -orderBy
{{ Fill orderBy Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -userid
If specified, only return this specific ID

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

### -search
Returns all users with a matching username, first name, last name, email address, or company name

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

### -details
Return full details of all users

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

### -all
{{ Fill all Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Date: 28/04/2019

## RELATED LINKS

[https://github.com/fletcherg/litmos-client](https://github.com/fletcherg/litmos-client)

