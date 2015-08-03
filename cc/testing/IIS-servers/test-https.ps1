$servers = get-content H:\Powershell\IIS-servers\iis-servers.txt

$web = New-Object Net.WebClient

foreach ($server in $servers) {
    echo $server
Try {
    $web.DownloadString("https://$server")
    } 
Catch {
    Write-Warning "$($error[0])"
    }
}