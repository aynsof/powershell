<#
.SYNOPSIS
    Resets password for 'wifi' account and emails it to Confluence
.EXAMPLE
    C:\PS>.\reset-wifipassword
.NOTES
    Author: James Kingsmill
    Date:   April 29, 2015
#>

$PW_LENGTH=7
$CONF_EMAILACCT="confmail@careconnect.org.au"
$SMTP_SERVER="mail.careconnect.org.au"
$EMAIL_SUBJECT="Wifi Password"
$AUTHTOKEN = '20t8jq[[spo12wefjkl;w'

#####################################
# Function Definitions
#####################################

Function Shuffle-String ($string) {
  # Randomize the order of characters in a given string
  $sa1 = $string.ToCharArray()
  $sa2 = Get-Random -InputObject $sa1 -Count ([int]::MaxValue)
  $string = [String]::Join("",$sa2)
  return $string
}

Function Get-TempPassword {
  # Generate string of valid characters
  $TempPassword=$()

  # Define character arrays
  $lowercase=@()
  $lowercase=[char[]]([char]'a'..[char]'z') # Lowercase
  $uppercase=@()
  $uppercase=[char[]]([char]'A'..[char]'Z') # Uppercase
  $number=@()
  $number=[char[]]([int][char]'0'..[int][char]'9') # Numerical
  $symbol=@()
  $symbol=[char[]]([int][char]'/'..[char]'!') # Symbols

  $TempPassword+=($uppercase | GET-RANDOM) # Single uppercase character
  $TempPassword+=($number | GET-RANDOM) # Single numerical character
  $TempPassword+=($symbol | GET-RANDOM) # Single symbolic character
  
  For ($loop=1; $loop -le $PW_LENGTH; $loop++) { # Comment
    $TempPassword+=($lowercase | GET-RANDOM)
  }
  
  $TempPassword = Shuffle-String($TempPassword)
  
  return $TempPassword
}

#####################################
# Main
#####################################

# Generate password
$Password = Get-TempPassword
$Date = Get-Date -format D
$HTMLBody = "Password as of " + $Date + " is <h3><p>Username: wifi</p><p>Password: " + $Password + "</p></h3>"

# Reset password for 'wifi' account
Set-ADAccountPassword -identity wifi -newpassword $(convertTo-SecureString $Password -asPlainText -force) -reset
Write-Host "Password reset"

Send-MailMessage -to $CONF_EMAILACCT -from $CONF_EMAILACCT -smtpserver $SMTP_SERVER -subject $EMAIL_SUBJECT -bodyashtml $HTMLBody
Write-Host "Confluence emailed"

$json = "{ ""auth_token"": ""$AUTHTOKEN"", ""text"": ""$Password""}"
Invoke-RestMethod -uri https://wifi-passwd.herokuapp.com/widgets/wifi -body $json -method "Post" -contenttype "application/json"
Write-Host "Password sent to https://wifi-passwd.herokuapp.com"