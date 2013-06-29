
#Generates a Kerberos keytab for all servers listed in the given $hostfile
#Assumes $hostfile is a list of simple hostnames (not FQDNs), separated by newlines

$hostfile = $args[0]

foreach ($srv in Get-Content $hostfile)
{
	$cmd = "ktpass -out " + $srv + "_keytab -pass C0mplic4ted_p@ss -princ HOST/" + $srv + ".bom.gov.au@BOM.GOV.AU -mapuser host_" + $srv + " -ptype KRB5_NT_PRINCIPAL /crypto AES256-SHA1"
	iex $cmd

}
