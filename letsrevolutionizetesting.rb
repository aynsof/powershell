$url = "http://letsrevolutionizetesting.com/challenge.json"
 
$web = New-Object Net.WebClient
 
while ($true) {
    $json = $web.DownloadString($url) | ConvertFrom-Json
    if ($json.follow){
        $url = $json.follow -replace "challenge", "challenge.json"
        #$url = $url -replace "challenge", "challenge.json"
        echo $url
    }
    else {
        Write-Output $json.message
        Break
    }
}
