---
external help file: litmos-client-help.xml
Module Name: litmos-client
online version: https://github.com/fletcherg/litmos-client
schema: 2.0.0
---

# Get-LitmosTeam

## SYNOPSIS
This function will get teams based on conditions.

## SYNTAX

```
Get-LitmosTeam [[-name] <String>] [[-parentteam] <String>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Get-LitmosTeam -name "All Users"
```

Will return all teams under "All Users"

## PARAMETERS

### -name
If specified, only return team with this name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -parentteam
{{ Fill parentteam Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Date: 30/04/2019

## RELATED LINKS

[https://github.com/fletcherg/litmos-client](https://github.com/fletcherg/litmos-client)

