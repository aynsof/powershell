$servers = get-content xenapp-servers.txt

foreach ($server in $servers) {
    echo $server
Try {
    Copy-Item -path H:\ax32.ddconfig -destination \\$server\c$\ax32.ddconfig
    } 
Catch {
    Write-Warning "$($error[0])"
    }
}