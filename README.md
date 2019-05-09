# litmos-client

Basic PowerShell client implementation for Litmos LMS API.

https://support.litmos.com/hc/en-us/articles/227734667-Overview-Developer-API

Only some functions have been implemented, and I got a bit lazy :cold_sweat:. Hopefully this is of use to someone :wink: :heart:

# Getting Started

You will need a Litmos account setup, and an API key

https://support.litmos.com/hc/en-us/articles/227734847-Retrieving-Your-API-Key


The following example script will use the same information you use to log into Manage.

The following example will let you login

```

$tenantName = "sandbox"
$apiKey = "943f6ae4-c986-44ec-b370-7570c8aa2c79"
$server = "api.litmos.com.au"

# Load the module into memory
iwr 'https://raw.githubusercontent.com/gfletche/litmos-client/master/litmos-client.psm1' | iex

# make connection to Litmos
Connect-Litmos -server $server -apiKey $apiKey -tenantName $tenantName

Get-LitmosUser -All

# Disconnect from Litmos
Disconnect-Litmos
```

# Functions
See below for a list of available commands.

[Connect-Litmos](Litmos/Connect-Litmos.md)

[Get-LitmosTeam](Litmos/Get-LitmosTeam.md)

[Get-LitmosTeamMember](Litmos/Get-LitmosTeamMember.md)

[Get-LitmosUser](Litmos/Get-LitmosUser.md)

[New-LitmosTeam](Litmos/New-LitmosTeam.md)

[New-LitmosUser](Litmos/New-LitmosUser.md)

[Remove-LitmosUser](Litmos/Remove-LitmosUser.md)

[Remove-LitmosTeam](Litmos/Remove-LitmosTeam.md)

[Remove-LitmosTeamMember](Litmos/Remove-LitmosTeamMember.md)

[Update-LitmosUser](Litmos/Update-LitmosUser.md)

[Disconnect-Litmos](Litmos/Disonnect-Litmos.md)


# To Do

* Remove some hacky shortcuts... sorry.. :sweat: :pensive:
* Add support for more litmos functions