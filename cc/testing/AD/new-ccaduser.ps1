param(
  [string]$firstName = $(throw "missing first name"),
  [string]$lastName = $(throw "missing last name"),
  [string]$location = $(throw "missing location"),
  [string]$groups = "defaultgroups.txt"
)

$PW_LENGTH=10
$MAILDATABASEHIGH="ccnexch03\Mailbox Database High"
$MAILDATABASEMEDIUM="ccnexch03\Mailbox Database Medium"
$MAILDATABASELOW="ccnexch03\Mailbox Database Low01"

# Generate account name by concatenating first initial and last name
$accountName=$firstName[0]+$lastName

# Generate email address by appending @careconnect.org.au
$emailAddress=$accountName.toLower()+"@careconnect.org.au"

#####################################
# Input Testing
#####################################

# Exit if user already exists in AD
$user = $(try {get-aduser -identity $accountName} catch {$null})
If ($User -ne $Null)
{
	write-host "!!! Username" $accountName "already exists !!! " -foregroundcolor "red"
	break
}

# Exit if location is invalid
$location = $location.toLower()
$validLocations = "abbotsford","ballina","banyo","bella vista","bendigo","diverse","doncaster","east brighton","echuca","lilydale","moonee ponds","redfern","tweed heads"
if (($validLocations -contains $location) -eq $false) {
  write-host "!!!" $location "is an invalid location !!! " -foregroundcolor "red"
  break
}
else {
  $locationPath = "OU=" + $location + ",OU=Locations,OU=Careconnect,DC=CConnect,DC=local"
}

#####################################
# Function Definitions
#####################################

Function Get-TempPassword {
  # Generate string of valid characters
  $alphabet=@()
  $alphabet=[char[]]([int][char]'1'..[int][char]'Z')

  For ($loop=1; $loop –le $PW_LENGTH; $loop++) {
    $TempPassword+=($alphabet | GET-RANDOM)
  }

  return $TempPassword
}

Function Get-UserMailDatabase {
  # Determine randomly which mail database to use
  $val = Get-Random -maximum 3
  switch ($val)
    {
	  0 { return $MAILDATABASEHIGH }
	  1 { return $MAILDATABASEMEDIUM }
	  2 { return $MAILDATABASELOW }
	}
}
	
#####################################
# Main
#####################################

write-Host "Creating " $accountName "..."

$Password = Get-TempPassword

# Create AD account
New-ADUser -sAMAccountName $accountName `
           -Name $($firstName + $lastName) `
 		   -GivenName $firstName `
		   -Surname $lastName `
		   -AccountPassword $(ConvertTo-SecureString $Password -AsPlainText -Force) `
		   -Path $locationPath `
		   -OtherAttributes @{mail=$emailAddress} `
		   -Enable $true -whatif

# Add account to groups
foreach ($group in (get-content $groups)) {
  Add-ADGroupMember -Identity $group -Members $accountName -whatif
}

# Create Exchange mailbox
$mailDatabase = get-UserMailDatabase
write-Host "Creating mailbox on" $mailDatabase
Enable-Mailbox $emailAddress -Database "$mailDatabase" -whatif

write-Host "Account created successfully."
echo $Password | clip
write-Host "Password has been sent to the clipboard."