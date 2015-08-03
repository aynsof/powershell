$NUMSYSADMINS = 3
$AUTHTOKEN = '20t8jq[[spo12wefjkl;w'

Add-PSSnapin vm*
import-module activedirectory
connect-viserver ccnvcs01 -WarningAction SilentlyContinue
connect-viserver ccnvcslab01 -WarningAction SilentlyContinue

Write-Host "Retrieving AD info..."
$numUsers = (Get-ADGroupMember 'ccnusers' | get-aduser | where {$_.enabled -like "True"}).count

Write-Host "Retrieving vSphere info..."
$numVMs = (get-vm | where {$_.powerstate -like 'PoweredOn'}).count

$numVMHosts = (get-vmhost).count

$freeSpaceGB, $capacityGB = 0
foreach ($datastore in get-datastore) {

  $freeSpaceGB += [int]($datastore.freespaceGB)
  $capacityGB += [int]($datastore.capacityGB)

}

$percentDatastoreUsage = [int](($freeSpaceGB/$capacityGB)*100)

$memoryUsageGB, $memoryTotalGB = 0

foreach ($VMhost in get-vmhost) {

  $memoryUsageGB += [int]($VMHost.memoryUsageGB)
  $memoryTotalGB += [int]($VMHost.memoryTotalGB)

  $numCPU += $VMHost.NumCpu

}

$percentMemoryUsage = [int](($memoryUsageGB/$memoryTotalGB)*100)

Write-Host "Retrieving Zendesk info..."

# Zendesk auth
$zenUsername = "jkingsmill@careconnect.org.au/token"
$zenToken = "Ejo2lUfkcMIVOTSK795bNDS8tHd7nud3I7mYHE70"

# Create REST parameters
$params = @{
  uri = "https://itcareconnect.zendesk.com/api/v2/search.json?query=type%3Aticket+status%3Aopen"; # retrieve Open tickets
  method = 'GET';
  Headers = @{
    Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($zenUsername):$($zenToken)"));
  } # End headers hash table
  
} # End params hash table

$json = Invoke-RestMethod @params
$numOpenTickets = $json.count

$params.uri = "https://itcareconnect.zendesk.com/api/v2/search.json?query=type%3Aticket+status%3Apending" # Retrieve Pending tickets
$json = Invoke-RestMethod @params
$numPendingTickets = $json.count

$params.uri = "https://itcareconnect.zendesk.com/api/v2/search.json?query=type%3Aticket+status%3Ahold" # Retrieve On-Hold tickets
$json = Invoke-RestMethod @params
$numOnHoldTickets = $json.count

$totalOpenTickets = $numOpenTickets + $numPendingTickets + $numOnHoldTickets # Sum all open tickets

Write-Host "Sending data to Heroku..."

Write-Host "Sending sysadmin info..."
$json = "{ ""auth_token"": ""$AUTHTOKEN"", ""current"": $NUMSYSADMINS}"
Invoke-RestMethod -uri https://jkccdash.herokuapp.com/widgets/sysadmins -body $json -method "Post" -contenttype "application/json"

Write-Host "Sending user info..."
$json = "{ ""auth_token"": ""$AUTHTOKEN"", ""current"": $numUsers}"
Invoke-RestMethod -uri https://jkccdash.herokuapp.com/widgets/users -body $json -method "Post" -contenttype "application/json"

Write-Host "Sending data and memory info..."
$json = "{ ""auth_token"": ""$AUTHTOKEN"", ""value"": $memoryUsageGB, ""max"": $memoryTotalGB}"
Invoke-RestMethod -uri https://jkccdash.herokuapp.com/widgets/datausage -body $json -method "Post" -contenttype "application/json"

$json = "{ ""auth_token"": ""$AUTHTOKEN"", ""value"": $freeSpaceGB, ""max"": $capacityGB}"
Invoke-RestMethod -uri https://jkccdash.herokuapp.com/widgets/memusage -body $json -method "Post" -contenttype "application/json"

Write-Host "Sending vSphere info..."
$json = @"
{
  "auth_token": "$AUTHTOKEN",
  "items": [
    {
      "label": "VMs",
      "value": $numVMs
    },
    {
      "label": "Hosts",
      "value": $numVMHosts
    },
    {
      "label": "CPUs",
      "value": $numCPU
    },
    {
      "label": "Memory Usage %",
      "value": $percentMemoryUsage
    },
    {
      "label": "Data Usage %",
      "value": $percentDatastoreUsage
    }
  ]
}
"@
Invoke-RestMethod -uri https://jkccdash.herokuapp.com/widgets/vsphere -body $json -method "Post" -contenttype "application/json"

Write-Host "Sending Zendesk info..."
$json = @"
{
  "auth_token": "$AUTHTOKEN",
  "items": [
    {
      "label": "Open Tickets",
      "value": $numOpenTickets
    },
    {
      "label": "Pending Tickets",
      "value": $numPendingTickets
    },
    {
      "label": "On-Hold Tickets",
      "value": $numOnHoldTickets
    }
  ]
}
"@
Invoke-RestMethod -uri https://jkccdash.herokuapp.com/widgets/zendesk -body $json -method "Post" -contenttype "application/json"

Write-Host "Completed!"