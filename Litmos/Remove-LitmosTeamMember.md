---
external help file: litmos-client-help.xml
Module Name: litmos-client
online version: https://github.com/fletcherg/litmos-client
schema: 2.0.0
---

# Remove-LitmosTeamMember

## SYNOPSIS
This function will remove a user from a team

## SYNTAX

```
Remove-LitmosTeamMember [-teamId] <String> [-UserId] <String> [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Remove-LitmosTeamMember -team f4kdjzprT_4 -user p5nz03k_3k4i
```

Will remove this user from this team

## PARAMETERS

### -teamId
ID of the team

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

### -UserId
ID of the user

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
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

