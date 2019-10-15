#region [Helpers]-------

function Connect-Litmos {
    <#
        .SYNOPSIS
        Create connection to Litmos API.
            
        .DESCRIPTION
        Creates authentication mechanism for subsequent API calls.
            
        .PARAMETER server
        The URL of your Litmos environment.
        Example: api.litmos.com.au/v1.svc
            
        .PARAMETER TenantName
        The name of your company
                                            
        .PARAMETER apiKey
        API key for your user account
            
        .EXAMPLE
        $Connection = @{
            server = $server
            tenantName = $tenantName 
            apiKey = $apiKey
        }
        Connect-Litmos @Connection
            
        .NOTES
        Date: 27/04/2019
        .LINK
        https://support.litmos.com/hc/en-us/articles/227734667-Overview-Developer-API
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$server,
        [Parameter(Mandatory=$true)]
        [string]$tenantName,
        [Parameter(Mandatory=$true)]
		[string]$apiKey,
        [switch]$Force
    )

	
	# this is stupid
	if ($global:LitmosConnection -and !$force) {
		Write-Verbose "Connect-Litmos: Using cached server information for tenant $($global:LitmosConnection:tenantName)"
		return
	}
	
    # Validate server
    $server = ($server -replace("http.*:\/\/",'') -split '/')[0] + "/v1.svc"

    $global:LitmosConnection = @{}
    
	$global:LitmosRateTime = Get-Date
	$global:LitmosRateCount = 0
		
	if (!$server -or !$apikey -or !$tenantname) {
	    Write-Error "Not enough details were passed to authenticate."
        return
    }

    # Create the Server Connection object    
    $global:LitmosConnection = @{
        Server = $Server
        tenantName = $tenantName
        apiKey = $apiKey
    }

    # Validate connection info
    Write-Verbose 'Validating authentication'
	$res = Invoke-LitmosRequest -endpoint "users" -limit 1
	#Invoke-Webrequest "https://$($global:litmosconnection.server)/users?apikey=$($global:litmosconnection.apiKey)&source=$($global:litmosconnection.tenantName)&limit=0"
	if ((![xml]$res.content).users) {
		Write-Warning 'Authentication failed. Clearing connection settings.'
        Disconnect-Litmos
        return
    }
    Write-Verbose 'Connection successful.'
    Write-Verbose '$LitmosConnection, variable initialized.'
}

function Disconnect-Litmos {
    <#
        .SYNOPSIS
        This will remove the Litmos authentication mechanism.
                          
        .EXAMPLE
        Disconnect-Litmos 
        .NOTES
        Date: 27/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
    param()
    $null = Remove-Variable -Name LitmosConnection -Scope global -Force -Confirm:$false -ErrorAction SilentlyContinue
    if($LitmosConnection -or $global:LitmosConnection) {
        Write-Error "There was an error clearing connection information.`n$($Error[0])"
    } else {
        Write-Verbose 'Disconnect-Litmos $LitmosConnection, variable removed.'
    }
}



function Invoke-LitmosRequest {
    <#
        .SYNOPSIS
        This function is used to handle all web requests to the Litmos Manage API.
        
        .DESCRIPTION
        This function is used to manage error handling with web requests.
        It will also handle retries of failed attempts.

        .PARAMETER Arguments
        A splat object of web request parameters

        .PARAMETER MaxRetry
        The maximum number of retry attempts

        .NOTES
        Date: 27/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
    param(
		$arguments,
		[Parameter(Mandatory=$true)]
		[string]$endpoint,
		[string]$method = "GET",
		[string]$body,
		[int]$rateLimitRequests = 50,
		[int]$rateLimitSeconds = 60,
		[int]$start,
		[int]$limit,	
		[switch]$paged
    )
	
	if (!$global:LitmosConnection) {
		$ErrorMessage = @()
        $ErrorMessage += "Not connected to a Manage server."
        $ErrorMessage +=  $_.ScriptStackTrace
        $ErrorMessage += ''    
        $ErrorMessage += '--> $LitmosConnection variable not found.'
        $ErrorMessage += "----> Run 'Connect-Litmos' to initialize the connection before issuing other Litmos functions."
        Write-Error ($ErrorMessage | Out-String)
        return
	}
	
	# rate limiter
	if (((Get-Date) - $global:LitmosRateTime).TotalSeconds -gt $rateLimitSeconds) {
		Write-Verbose "API request limit reset"
		$global:LitmosRateTime = Get-Date
		$global:LitmosRateCount = 0
	} else {
		Write-Verbose "API request count incremented"
		$global:LitmosRateCount++
	}

	if ($global:LitmosRateCount -ge $rateLimitRequests) {
		Write-Host "API request limit reached, backing off..."
		do  {
			sleep 1
		} until (((Get-Date) - $global:LitmosRateTime).TotalSeconds -gt $rateLimitSeconds)
	}
	
	if ($method -eq "GET") {
		
			$additionalOptions = ""
			if ($limit) {
				if ($limit -ge 0 -AND $limit -le 1000) {
					$additionalOptions+="&limit=$($limit)"
				} else {
					$additionalOptions+="&limit=1000"
				}
			}
			
			if ($start) {
				$additionalOptions+="&start=$($start)"
			}
			
			if ($arguments.search) {
				$additionalOptions+="&search=$($arguments.search)"
			}
			
			$WebRequestArguments = @{
            URI = "https://$($global:litmosconnection.server)/$($endpoint)?source=$($global:litmosconnection.tenantName)$($additionalOptions)"
            Headers = @{ APIKey = $global:litmosconnection.apiKey }
	    Method = "GET"
			}
        
	} elseif ($method -eq "PUT") {
		$WebRequestArguments = @{
            URI = "https://$($global:litmosconnection.server)/$($endpoint)?source=$($global:litmosconnection.tenantName)"
            Headers = @{ APIKey = $global:litmosconnection.apiKey }
	    Method = "PUT"
            Body = $Body
			ContentType = "application/xml"
        }
	} elseif ($method -eq "POST") {
		$WebRequestArguments = @{
            URI = "https://$($global:litmosconnection.server)/$($endpoint)?source=$($global:litmosconnection.tenantName)"
            Headers = @{ APIKey = $global:litmosconnection.apiKey }
	    Method = "POST"
            Body = $Body
			ContentType = "application/xml"
        }
	} elseif ($method -eq "DELETE") {
		$WebRequestArguments = @{
            URI = "https://$($global:litmosconnection.server)/$($endpoint)?source=$($global:litmosconnection.tenantName)"
            Headers = @{ APIKey = $global:litmosconnection.apiKey }
	    Method = "DELETE"
        }
	} else {
		Write-Error "Method $($method) not implemented"
		return
	}
	
    # Issue request
    try {
        $Result = Invoke-WebRequest @WebRequestArguments -UseBasicParsing
    } 
    catch {
        if($_.Exception.Response){
            # Read exception response
            $ErrorStream = $_.Exception.Response.GetResponseStream()
            $Reader = New-Object System.IO.StreamReader($ErrorStream)
            $global:ErrBody = $Reader.ReadToEnd() | ConvertFrom-Json

            # Start error message
            $ErrorMessage = @()

            if($errBody.code){
                $ErrorMessage += "An exception has been thrown."
                $ErrorMessage +=  $_.ScriptStackTrace
                $ErrorMessage += ''    
                $ErrorMessage += "--> $($ErrBody.code)"
                if($errBody.code -eq 'Unauthorized'){
                    $ErrorMessage += "-----> $($ErrBody.message)"
                    $ErrorMessage += "-----> Use 'Disconnect-Litmos' or 'Connect-Litmos -Force' to set new authentication."
                } 
                else {
                    $ErrorMessage += "-----> $($ErrBody.message)"
                    $ErrorMessage += "-----> ^ Error has not been documented please report. ^"
                }
            }
        }

        if ($_.ErrorDetails) {
            $ErrorMessage += "An error has been thrown."
            $ErrorMessage +=  $_.ScriptStackTrace
            $ErrorMessage += ''
            $global:errDetails = $_.ErrorDetails | ConvertFrom-Json
            $ErrorMessage += "--> $($errDetails.code)"
            $ErrorMessage += "--> $($errDetails.message)"
            if($errDetails.errors.message){
                $ErrorMessage += "-----> $($errDetails.errors.message)"
            }
        }
        Write-Error ($ErrorMessage | out-string)
        return
    }
	## this is a bit shit lol, need to rewrite...
	if ($method -eq "GET") {
		
		if ($arguments.UserId) {
			return ([xml]$result.content.replace(">System.Xml.XmlElement<","><")).ChildNodes
		} else {
			return ([xml]$result.content.replace(">System.Xml.XmlElement<","><")).ChildNodes.SelectNodes("*")
		}
		
	} else {
		return $result
	}
}

function Invoke-LitmosAllResult {
    <#
        .SYNOPSIS
        This will handle web get requests for all results to the Litmos API
            
        .DESCRIPTION
        This will enable pagination and loop all results.
            
        .ENDPOINT
        API Endpoint to query
                
        .EXAMPLE
        Invoke-LitmosAllResult -endpoint "users"
            
        .NOTES
        Date: 28/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
    param(
		$arguments,
		[Parameter(Mandatory=$true)]
        [string]$endpoint
		)

	if($arguments.all) {
		$result = @()
		$n = 500; $p = 0
		do {
			$res = Invoke-LitmosRequest -endpoint $endpoint -limit $n -start $($n * $p) -Arguments $arguments
			$result += $res
			$p++
		} while ($res.length -eq $n)
		
		return $result
	
	} else {
		$result = Invoke-LitmosRequest -endpoint $endpoint -limit 1000 -Arguments $arguments
		if ($result.length -eq 1000) {
			Write-Warning "First 1000 results returned. More available, return with -all"
		}
		
		return $result
	}
}
#endregion [Helpers]-------


#region [Users]-------
function Get-LitmosUser {
    <#
        .SYNOPSIS
        This function will list Users based on conditions.

        .PARAMETER userid
        If specified, only return this specific ID

        .PARAMETER details
        Return full details of all users

		.PARAMETER search
        Returns all users with a matching username, first name, last name, email address, or company name
		
        .EXAMPLE
		Get-LitmosUser -all
        Will return all users

		.EXAMPLE
		Get-LitmosUser -all
        Will return all users with details
		
        .NOTES
        Date: 28/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('asc','desc')] 
        $orderBy,
        [string]$userid,
		[string]$search,
        [switch]$details,
		[switch]$all
    )

	if ($details) {
		
		$res = Invoke-LitmosAllResult -endpoint "Users/$($userId)/Details" -Arguments $PsBoundParameters
		
	
	} else {
	
		if ($userid) {
			$res = Invoke-LitmosAllResult -endpoint "Users/$($userId)" -Arguments $PsBoundParameters
		} else {
			$res = Invoke-LitmosAllResult -endpoint "Users" -Arguments $PsBoundParameters
		}
	}
	
	#return $res | % { ConvertFrom-XML $_ }
	return $res
	 
}

function Update-LitmosUser {
    <#
        .SYNOPSIS
        This function will Update a litmos user based on ID

        .PARAMETER userid
        ID of the user to update

        .PARAMETER username
        UserName of the user to update
		
		.PARAMETER firstname
		FirstName of the user to upate
		
		.PARAMETER lastname
		LastName of the user to update
		
		.PARAMETER fullname
		FullName of the user to update
		
		.PARAMETER email
		Email of the user to update.
		
        .NOTES
        Date: 28/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
    param(
        $properties,
		$manager,
		[Parameter(Mandatory=$true)]
        [string]$userid,
		[Parameter(Mandatory=$true)]
        [string]$UserName,
		[Parameter(Mandatory=$true)]
        [string]$FirstName,
		[Parameter(Mandatory=$true)]
        [string]$LastName,
		[Parameter(Mandatory=$true)]
        [string]$FullName,
        [string]$Email,
		[Parameter(Mandatory=$true)]
        [string]$AccessLevel,
		[Parameter(Mandatory=$true)]
		[string]$DisableMessages,
		[Parameter(Mandatory=$true)]
		[string]$Active,
		[string]$Skype,
		[string]$PhoneWork,
		[string]$PhoneMobile,
		[string]$LastLogin,
		[Parameter(Mandatory=$true)]
		[string]$LoginKey,
		[Parameter(Mandatory=$true)]
		[string]$isCustomuserName,
		[string]$Password,
		[Parameter(Mandatory=$true)]
		[string]$SkipFirstLogin,
		[Parameter(Mandatory=$true)]
		[string]$TimeZone,
		[string]$Street1,
		[string]$Street2,
		[string]$City,
		[string]$State,
		[string]$PostalCode,
		[string]$Country,
		[string]$CompanyName,
		[string]$JobTitle,
		[string]$CustomField1,
		[string]$CustomField10,
		[string]$Culture,
		[string]$Brand,
		[string]$ManagerId,
		[string]$EnableTextNotifications,
		[string]$Website,
		[string]$Twitter,
		[string]$ExpirationDate
		)
	
	$body = "<User xmlns:i=""http://www.w3.org/2001/XMLSchema-instance"">"
	$body += "<Id>$($UserId)</Id>"
    $body += "<UserName>$($UserName)</UserName>"
    $body += "<FirstName>$($FirstName)</FirstName>"
    $body += "<LastName>$($LastName)</LastName>"
    $body += "<FullName>$($FullName)</FullName>"
    if ($email -OR $email -eq "") { $body += "<Email>$($Email)</Email>" }
	if ($AccessLevel) { $body += "<AccessLevel>$($AccessLevel)</AccessLevel>" }
	if ($DisableMessages) { $body += "<DisableMessages>$($DisableMessages)</DisableMessages>" }
	if ($Active) { $body += "<Active>$($Active)</Active>" }
	if ($Skype) { $body += "<Skype>$($Skype)</Skype>" }
	if ($PhoneWork) { $body += "<PhoneWork>$($PhoneWork)</PhoneWork>" }
	if ($PhoneMobile) { $body += "<PhoneMobile>$($PhoneMobile)</PhoneMobile>" }
	if ($LastLogin -OR $LastLogin -eq "") { $body += "<LastLogin>$($LastLogin)</LastLogin>" }
	if ($LoginKey) { $body += "<LoginKey>$($LoginKey)</LoginKey>" }
	if ($isCustomUsername) { $body += "<IsCustomUsername>$($isCustomUsername)</IsCustomUsername>" }
	if ($Password) { $body += "<Password>$($Password)</Password>" }
	if ($SkipFirstLogin) { $body += "<SkipFirstLogin>$($SkipFirstLogin)</SkipFirstLogin>" }
	if ($TimeZone) { $body += "<TimeZone>$($TimeZone)</TimeZone>" }
	if ($Street1) { $body += "<Street1>$($Street1)</Street1>" }
	if ($Street2) { $body += "<Street2>$($Street2)</Street2>" }
	if ($City) { $body += "<City>$($City)</City>" }
	if ($State) { $body += "<State>$($State)</State>" }
	if ($PostalCode) { $body += "<PostalCode>$($PostalCode)</PostalCode>" }
	if ($Country) { $body += "<Country>$($Country)</Country>" }
	if ($CompanyName) { $body += "<CompanyName>$($CompanyName)</CompanyName>" }
	if ($JobTitle) { $body += "<JobTitle>$($JobTitle)</JobTitle>" }
	if ($CustomField1) { $body += "<CustomField1>$($CustomField1)</CustomField1>" }
	if ($CustomField10) { $body += "<CustomField10>$($CustomField10)</CustomField10>" }
	if ($Culture) { $body += "<Culture>$($Culture)</Culture>" }
	if ($Brand) { $body += "<Brand>$($Brand)</Brand>" }
	if ($ManagerId) { $body += "<ManagerId>$($ManagerId)</ManagerId>" }
	if ($EnableTextNotifications) { $body += "<EnableTextNotifications>$($EnableTextNotifications)</EnableTextNotifications>" }
	if ($Website) { $body += "<Website>$($Website)</Website>" }
	if ($Twitter) { $body += "<Twitter>$($Twitter)</Twitter>" }
	if ($ExpirationDate) { $body += "<ExpirationDate>$($ExpirationDate)</ExpirationDate>" }
	$body += "</User>"
	
		
	$endpoint = "users/$($userId)"
	
	
	write-debug $body
	write-debug $endpoint

	$res = Invoke-LitmosRequest -endpoint $endpoint -method "PUT" -body $body.replace("&","&amp;")
	if ($res.StatusCode -eq 200) {
		Write-Verbose "Updated OK"
	} else {
		Write-Error "Error in updating user $($userId)"
	}
	
}


function New-LitmosUser {
    <#
        .SYNOPSIS
        This function will Create a litmos user based on ID

        .PARAMETER userid
        ID of the user to update

        .PARAMETER propeties
        Hashtable of properties to update. Must include required parameters per API doc.
		
        .NOTES
        Date: 28/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
    param(
        $properties
    )
	
	$endpoint = "users"
	
	$reqFields = "UserName","FirstName","LastName","FullName", `
			"Email","Active","PhoneWork","PhoneMobile", "Password", `
			"Street1","Street2","City","State","PostalCode","Country", `
			"CompanyName","JobTitle","CustomField1","CustomField10","Website"
	
	foreach ($reqField in $reqFields) {
		if ($properties.Keys -notcontains $reqField) {
			Write-Error "Did not include $($reqField) in update params"
			return
		}
	}

	
$body = @"
<User xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
	<Id></Id>
    <UserName>$($properties.UserName)</UserName>
    <FirstName>$($properties.FirstName)</FirstName>
    <LastName>$($properties.LastName)</LastName>
    <FullName>$($properties.FullName)</FullName>
    <Email>$($properties.Email)</Email>
	<AccessLevel>learner</AccessLevel>
	<DisableMessages>false</DisableMessages>
    <Active>$($properties.Active)</Active>
	<Skype></Skype>
	<PhoneWork>$($properties.PhoneWork)</PhoneWork>
	<PhoneMobile>$($properties.PhoneMobile)</PhoneMobile>
	<LastLogin></LastLogin> 
	<LoginKey></LoginKey>
	<IsCustomUsername>false</IsCustomUsername>
	<Password>$($properties.Password)</Password>
    <SkipFirstLogin>true</SkipFirstLogin>
	<TimeZone></TimeZone>
    <Street1>$($properties.Street1)</Street1>
    <Street2>$($properties.Street2)</Street2>
    <City>$($properties.City)</City>
    <State>$($properties.State)</State>
    <PostalCode>$($properties.PostalCode)</PostalCode>
    <Country>$($properties.Country)</Country>
    <CompanyName>$($properties.CompanyName)</CompanyName>
    <JobTitle>$($properties.JobTitle)</JobTitle>
    <CustomField1>$($properties.CustomField1)</CustomField1>
    <CustomField10>$($properties.CustomField10)</CustomField10>
    <Website>$($properties.Website)</Website>
</User>
"@.replace("&","&amp;")

	Write-Debug $body
	
	$res = Invoke-LitmosRequest -endpoint $endpoint -method "POST" -body $body
	if ($res.StatusCode -eq 200) {
		Write-Verbose "Updated OK"
		return $true
	} else {
		Write-Error "Error in creating user"
		return $false
	}	
}

function Remove-LitmosUser {
    <#
        .SYNOPSIS
        This function will remove a litmos user based on ID

        .PARAMETER userid
        ID of the user to remove
		
        .NOTES
        Date: 28/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
    param(
		[Parameter(Mandatory=$true)]
        [string]$userid
    )
	
	$endpoint = "users/$($userId)"

	$res = Invoke-LitmosRequest -endpoint $endpoint -method "DELETE"
	if ($res.StatusCode -eq 200) {
		Write-Verbose "Deleted OK"
		return $true
	} else {
		Write-Error "Error in deleting user $($userId)"
		return $false
	}
}
#endregion [Users]-------


#region [Teams]-------

function Get-LitmosTeam {
    <#
        .SYNOPSIS
        This function will get teams based on conditions.

        .PARAMETER name
        If specified, only return team with this name

		.PARAMETER parent
        ID of parent team to retrieve teams for
		
        .EXAMPLE
		Get-LitmosTeam -name "All Users"
        Will return all teams under "All Users"

        .NOTES
        Date: 30/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
    param(
		[String]$name,
		[String]$parentteam
		)
		
	if ($parentteam) {
		$endpoint = "teams/$($parentteam)/teams"
	} else {
		$endpoint = "teams"
	}
	
	$res = Invoke-LitmosAllResult -endpoint $endpoint -Arguments $PsBoundParameters
	
	if ($name) {
		return $res | ? {$_.name -eq $name}
	} else {
		return $res
	}
	
}


function New-LitmosTeam {
    <#
        .SYNOPSIS
        This function will Create a litmos team

        .PARAMETER name
        Name of the team to create
		
		.PARAMETER description
        Description of the team
		
		.PARAMETER parentteam
        ID of the parent team

        .NOTES
        Date: 28/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
		[string]$name,
		[string]$description,
		[string]$parentteam
    )


$body = @"
<Team xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
	<Id></Id>
    <Name>$($name)</Name>
    <Description>$($description)</Description>
</Team>
"@.replace("&","&amp;")	

	if ($parentteam) {
		$endpoint = "teams/$($parentteam)/teams"
		Write-Verbose "Creating team $($name) under $($parentteam)..."
	} else {
		$endpoint = "teams"
		Write-Verbose "Creating team $($name)..."
	}
	
	Write-Verbose "Create team endpoint $($endpoint)"
	$res = Invoke-LitmosRequest -endpoint $endpoint -method "POST" -body $body
	
	if ($res.StatusCode -eq 201) {
		Write-Verbose "Team created OK"
		return $true
	} else {
		Write-Error "Error in creating team"
		return $false
	}	
}


function Get-LitmosTeamMember {
    <#
        .SYNOPSIS
        This function will get team members based on conditions.

        .PARAMETER team
        ID of the team

        .EXAMPLE
		Get-LitmosTeamMember -team f4kdjzprT_4
        Will return all users that are a member of this team

        .NOTES
        Date: 30/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
    param(
		[Parameter(Mandatory=$true)]
		[String]$team
		)
		
	$endpoint = "teams/$($team)/users"
	
	$res = Invoke-LitmosAllResult -endpoint $endpoint -Arguments $PsBoundParameters
	
	return $res
}


function Remove-LitmosTeam {
    <#
        .SYNOPSIS
        This function will get delete a litmos team

        .PARAMETER team
        ID of the team

        .EXAMPLE
		Remove-LitmosTeamMember -team f4kdjzprT_4
        Will delete this team

        .NOTES
        Date: 30/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
    param(
		[Parameter(Mandatory=$true)]
		[String]$team
		)
		
	$endpoint = "teams/$($team)"
	
	$res = Invoke-LitmosRequest -endpoint $endpoint -Method "DELETE"
	
	if ($res.StatusCode -eq 200) {
		Write-Verbose "Team deleted OK"
		return $true
	} else {
		Write-Error "Error in deleting team"
		return $false
	}	
	
}


function Add-LitmosTeamMember{
    <#
        .SYNOPSIS
        This function will add a user to a team

        .PARAMETER team
        ID of the team
		
		.PARAMETER userid
        ID of the user
		
		.PARAMETER username
        username of the user

		.PARAMETER firstname
        first name of the user
		
		.PARAMETER lastname
        last name of the user
		
        .EXAMPLE
		Add-LitmosTeamMember -team f4kdjzprT_4
        Will delete this team

        .NOTES
        Date: 30/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
	Param(
	[Parameter(Mandatory=$true)]
	[String]$teamId,
	[String]$UserId,
	[String]$UserName,
	[String]$FirstName,
	[String]$LastName,
	$UserList
	)

	if(!$UserList -AND !$UserId) {
		Write-Error "Must specify at least a User ID or UserList object"
		return
	}
	
	if ($UserId) {
		if (!$username -or !$firstname -or !$lastname) {
		Write-Verbose "Not enough details listed, retrieving user"
		$r = Get-LitmosUser -UserId $userId
		if ($r) {
			$username = $r.username
			$firstname = $r.firstname
			$lastname = $r.lastname
		} else {
			Write-Error "Can't find user"
			return
		}
		}
		

$body = @"
<Users xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
<User>
	<Id>$($userId)</Id>
	<UserName>$($UserName)</UserName>  
   <FirstName>$($FirstName)</FirstName>  
   <LastName>$($LastName)</LastName>  
</User>
	</Users>
"@.replace("&","&amp;")			
	
	} elseif ($UserList) {
	
	Write-Verbose "Adding $($UserList.count) users to team $($teamId)"


$body = @"
<Users xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
"@
foreach ($u in $UserList) {
Write-Verbose "including $($u.id) $($u.username) $($u.firstname) $($u.lastname)"
$body += @"
<User>
	<Id>$($u.Id)</Id>
	<UserName>$($u.username)</UserName>  
   <FirstName>$($u.firstname)</FirstName>  
   <LastName>$($u.lastname)</LastName>  
</User>
"@.replace("&","&amp;")	
}
$body += @"
</Users>
"@
	}

	

	$endpoint = "teams/$($teamId)/users"
	Write-Debug $endpoint
	Write-Debug $body
	$res = Invoke-LitmosRequest -endpoint $endpoint -method "POST" -body $body
	
	if ($res.StatusCode -eq 201) {
		Write-Verbose "user added OK"
		return $true
	} else {
		Write-Error "Error in adding user to team"
		return $false
	}	
}


function Remove-LitmosTeamMember{
    <#
        .SYNOPSIS
        This function will remove a user from a team

        .PARAMETER teamid
        ID of the team
		
		.PARAMETER userid
        ID of the user
		
        .EXAMPLE
		Remove-LitmosTeamMember -team f4kdjzprT_4 -user p5nz03k_3k4i
        Will remove this user from this team

        .NOTES
        Date: 30/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
	Param(
	[Parameter(Mandatory=$true)]
	[String]$teamId,
	[Parameter(Mandatory=$true)]
	[String]$UserId
	)

	$endpoint = "teams/$($teamId)/users/$($userId)"
	$res = Invoke-LitmosRequest -endpoint $endpoint -Method "DELETE"
}

#endregion [Teams]-------
