Write-Verbose "Loading the Exchange snapin"

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue

. $env:ExchangeInstallPath\bin\RemoteExchange.ps1

Connect-ExchangeServer -auto -AllowClobber