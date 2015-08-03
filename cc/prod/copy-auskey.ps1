
#Get UserName
param(
    [Parameter(Mandatory = $true,
                    Position = 0)]
    [String]
    $user
    )

# Add Citrix snapin
if ((Get-PSSnapin "Citrix.XenApp.Commands" -EA silentlycontinue) -eq $null) {
	try { Add-PSSnapin Citrix.XenApp.Commands -ErrorAction Stop }
	catch { write-error "Error loading XenApp Powershell snapin"; Return }
}

$domain = "CCONNECT"
$domainuser = $domain + "\"+$user

# Target path
$target = "\\ccnfnp01\d$\AUSkey\" + $user

# XenApperver the user currently has a Published Desktop session open on
$server = (Get-XASession -AccountDisplayName $domainuser | where-object { $_.state -match 'active' -and $_.browsername -match 'Published Desktop'} | Select-Object ServerName).ServerName

# Source path
$source = "\\" + $server + "\c$\Users\" + $user + "\AppData\Roaming\AUSkey"

Write-Host "Copying from "
Write-Host $source
Write-Host "to destination directory"
Write-Host $target

Copy-Item -recurse $source $target 