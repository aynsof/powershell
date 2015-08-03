# Find all Windows Servers in AD
$servers = Get-ADComputer -filter {OperatingSystem -Like "Windows Server*"} | select-object -expandproperty dnshostname

# Query each for W3SVC service
foreach ($server in $servers) {
  $iis = (Get-Service w3svc -computername $server) 2> $null
  if ($iis.status -eq "running") {
    echo $server
  }
}