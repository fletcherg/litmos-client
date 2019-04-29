#region [Helpers]-------
function ConvertFrom-XmlPart {
    param(
        $xml
    )
	# https://consciouscipher.wordpress.com/2015/06/05/converting-xml-to-powershell-psobject/ 
    $hash = @{}
    $xml | Get-Member -MemberType Property | `
        % {
            $name = $_.Name
            if ($_.Definition.StartsWith("string ")) {
                $hash.($Name) = $xml.$($Name)
            } elseif ($_.Definition.StartsWith("System.Object[] ")) {
                $obj = $xml.$($Name)
                $hash.($Name) = $($obj | %{ $_.tag }) -join "; "
            } elseif ($_.Definition.StartsWith("System.Xml")) {
                $obj = $xml.$($Name)
                $hash.($Name) = @{}
                if ($obj.HasAttributes) {
                    $attrName = $obj.Attributes | Select-Object -First 1 | % { $_.Name }
                    if ($attrName -eq "tag") {
                        $hash.($Name) = $($obj | % { $_.tag }) -join "; "
                    } else {
                        $hash.($Name) = ConvertFrom-XmlPart $obj
                    }
                }
                if ($obj.HasChildNodes) {
                    $obj.ChildNodes | % { $hash.($Name).($_.Name) = ConvertFrom-XmlPart $($obj.$($_.Name)) }
                }
            }
        }
    return $hash
}
 
function ConvertFrom-Xml {
    param(
        $xml
    )
    $hash = ConvertFrom-XmlPart($xml)
    return New-Object PSObject -Property $hash
}

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
        Author: fletcherg
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

	
	if ($global:LitmosConnection -and !$force) {
		Write-Verbose "Using cached server information"
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
        Author: fletcherg
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
        Write-Verbose '$LitmosConnection, variable removed.'
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
        Author: fletcherg
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
	
	
	
	### Build web request
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
            URI = "https://$($global:litmosconnection.server)/$($endpoint)?apikey=$($global:litmosconnection.apiKey)&source=$($global:litmosconnection.tenantName)$($additionalOptions)"
            Method = "GET"
			}
        
	} elseif ($method -eq "PUT") {
		$WebRequestArguments = @{
            URI = "https://$($global:litmosconnection.server)/$($endpoint)?apikey=$($global:litmosconnection.apiKey)&source=$($global:litmosconnection.tenantName)"
            Method = "PUT"
            Body = $Body
			ContentType = "application/xml"
        }
	} elseif ($method -eq "POST") {
		$WebRequestArguments = @{
            URI = "https://$($global:litmosconnection.server)/$($endpoint)?apikey=$($global:litmosconnection.apiKey)&source=$($global:litmosconnection.tenantName)"
            Method = "POST"
            Body = $Body
			ContentType = "application/xml"
        }
	} elseif ($method -eq "DELETE") {
		$WebRequestArguments = @{
            URI = "https://$($global:litmosconnection.server)/$($endpoint)?apikey=$($global:litmosconnection.apiKey)&source=$($global:litmosconnection.tenantName)"
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
	if ($method -eq "GET") {
		return ([xml]$result.content).ChildNodes.SelectNodes("*")
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
        Author: fletcherg
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
        Author: fletcherg
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
		$res = Invoke-LitmosAllResult -endpoint "Users/Details" -Arguments $PsBoundParameters
	} else {
		$res = Invoke-LitmosAllResult -endpoint "Users" -Arguments $PsBoundParameters
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

        .PARAMETER propeties
        Hashtable of properties to update. Must include required parameters per API doc.
		
        .NOTES
        Author: fletcherg
        Date: 28/04/2019

        .LINK
        https://github.com/fletcherg/litmos-client
    #>
    [CmdletBinding()]
    param(
        $properties,
		$manager,
		[Parameter(Mandatory=$true)]
        [string]$userid
    )
	
	if ($properties) {
		$reqFields = "Id","UserName","FirstName","LastName","FullName", `
				"Email","Active","PhoneWork","PhoneMobile","SkipFirstLogin", `
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
	<Id>$($properties.Id)</Id>
    <UserName>$($properties.UserName)</UserName>
    <FirstName>$($properties.FirstName)</FirstName>
    <LastName>$($properties.LastName)</LastName>
    <FullName>$($properties.FullName)</FullName>
    <Email>$($properties.Email)</Email>
    <Active>$($properties.Active)</Active>
	<PhoneWork>$($properties.PhoneWork)</PhoneWork>
	<PhoneMobile>$($properties.PhoneMobile)</PhoneMobile>
    <SkipFirstLogin>$($properties.SkipFirstLogin)</SkipFirstLogin>
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

	} elseif ($manager) {
		$reqFields = "Id","UserName","FirstName","LastName","FullName", `
				"Email","SkipFirstLogin", "ManagerId"
		
		foreach ($reqField in $reqFields) {
			if ($manager.Keys -notcontains $reqField) {
				Write-Error "Did not include $($reqField) in update params"
				return
			}
		}

$body = @"
<User xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
	<Id>$($manager.Id)</Id>
    <UserName>$($manager.UserName)</UserName>
    <FirstName>$($manager.FirstName)</FirstName>
    <LastName>$($manager.LastName)</LastName>
    <FullName>$($manager.FullName)</FullName>
    <Email>$($manager.Email)</Email>
    <SkipFirstLogin>$($manager.SkipFirstLogin)</SkipFirstLogin>
    <ManagerId>$($manager.ManagerId)</ManagerId>
</User>
"@.replace("&","&amp;")
	}
	
	$endpoint = "users/$($userId)"



	$res = Invoke-LitmosRequest -endpoint $endpoint -method "PUT" -body $body
	if ($res.StatusCode -eq 200) {
		Write-Verbose "Updated OK"
		return $true
	} else {
		Write-Error "Error in updating user $($userId)"
		return $false
	}
	
}


function Create-LitmosUser {
    <#
        .SYNOPSIS
        This function will Create a litmos user based on ID

        .PARAMETER userid
        ID of the user to update

        .PARAMETER propeties
        Hashtable of properties to update. Must include required parameters per API doc.
		
        .NOTES
        Author: fletcherg
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
        Author: fletcherg
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


#endregion [Teams]-------