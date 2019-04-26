# litmos-client

Basic PowerShell client implementation for Litmos LMS API.

https://support.litmos.com/hc/en-us/articles/227734667-Overview-Developer-API

# Getting Started

You will need a Litmos account setup, and an API key

https://support.litmos.com/hc/en-us/articles/227734847-Retrieving-Your-API-Key


The following example script will use the same information you use to log into Manage.

The following example will let you login

```

$apiUrl = "litmos.com.au"
$tenantName = "testTenant"
$apiKey = "blablabla"

$Credentials = Get-Credential

# Load the module into memory
iwr 'https://raw.githubusercontent.com/gfletche/litmos-client/master/litmos-client.psm1' | iex

# Connect to Manage server
Connect-Litmos -url $apiURL -tenantName $TenantName -apiKey $apiKey


Get-LitmosUser -All

# Disconnect from Litmos
Disconnect-Litmos
```


# Functions
See below for a list of available commands.

[Connect-Litmos](Litmos/Connect-Litmos.md)

[Create-LitmosTeam](Litmos/Create-LitmosTeam.md)

[Create-LitmosUser](Litmos/Create-LitmosUser.md)

[Get-LitmosTeam](Litmos/Get-LitmosTeam.md)

[Get-LitmosUser](Litmos/Get-LitmosUser.md)

[Update-LitmosUser](Litmos/Update-LitmosUser.md)

[Disconnect-Litmos](Litmos/Disonnect-Litmos.md)
