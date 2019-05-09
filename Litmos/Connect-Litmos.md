---
external help file: litmos-client-help.xml
Module Name: litmos-client
online version: https://support.litmos.com/hc/en-us/articles/227734667-Overview-Developer-API
schema: 2.0.0
---

# Connect-Litmos

## SYNOPSIS
Create connection to Litmos API.

## SYNTAX

```
Connect-Litmos [-server] <String> [-tenantName] <String> [-apiKey] <String> [-Force] [<CommonParameters>]
```

## DESCRIPTION
Creates authentication mechanism for subsequent API calls.

## EXAMPLES

### EXAMPLE 1
```
$Connection = @{
```

server = $server
    tenantName = $tenantName 
    apiKey = $apiKey
}
Connect-Litmos @Connection

## PARAMETERS

### -server
The URL of your Litmos environment.
Example: api.litmos.com.au/v1.svc

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

### -tenantName
The name of your company

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

### -apiKey
API key for your user account

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
{{ Fill Force Description }}

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
Date: 27/04/2019

## RELATED LINKS

[https://support.litmos.com/hc/en-us/articles/227734667-Overview-Developer-API](https://support.litmos.com/hc/en-us/articles/227734667-Overview-Developer-API)

