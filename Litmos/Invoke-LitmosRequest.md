---
external help file: litmos-client-help.xml
Module Name: litmos-client
online version: https://github.com/fletcherg/litmos-client
schema: 2.0.0
---

# Invoke-LitmosRequest

## SYNOPSIS
This function is used to handle all web requests to the Litmos Manage API.

## SYNTAX

```
Invoke-LitmosRequest [[-arguments] <Object>] [-endpoint] <String> [[-method] <String>] [[-body] <String>]
 [[-rateLimitRequests] <Int32>] [[-rateLimitSeconds] <Int32>] [[-start] <Int32>] [[-limit] <Int32>] [-paged]
 [<CommonParameters>]
```

## DESCRIPTION
This function is used to manage error handling with web requests.
It will also handle retries of failed attempts.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -arguments
A splat object of web request parameters

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

### -endpoint
{{ Fill endpoint Description }}

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

### -method
{{ Fill method Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: GET
Accept pipeline input: False
Accept wildcard characters: False
```

### -body
{{ Fill body Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -rateLimitRequests
{{ Fill rateLimitRequests Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 50
Accept pipeline input: False
Accept wildcard characters: False
```

### -rateLimitSeconds
{{ Fill rateLimitSeconds Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 60
Accept pipeline input: False
Accept wildcard characters: False
```

### -start
{{ Fill start Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -limit
{{ Fill limit Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -paged
{{ Fill paged Description }}

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

[https://github.com/fletcherg/litmos-client](https://github.com/fletcherg/litmos-client)

