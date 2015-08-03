<#
.SYNOPSIS
    Creates user account and mailbox
.PARAMETER firstName
.PARAMETER lastName
.PARAMETER accountName - the user's logon name
.PARAMETER location - one of "abbotsford","ballina","banyo","bella vista","bendigo","dandenong","diverse","doncaster","east brighton","echuca","lilydale","moonee ponds","redfern","tweed heads"
.PARAMETER role - one of "casemanager", "admin"
.EXAMPLE
    C:\PS>.\new-ccaduser Joe Bloggs jbloggs "moonee ponds" "casemanager"
.NOTES
    Author: James Kingsmill
    Date:   February 18, 2015
#>

param(
  [Parameter(Position=0,Mandatory=$true)]
  [string]$firstName,
  [Parameter(Position=1,Mandatory=$true)]
  [string]$lastName,
  [Parameter(Position=2,Mandatory=$true)]
  [string]$accountName,
  [Parameter(Position=3,Mandatory=$true)]
  [string]$location,
  [Parameter(Position=4,Mandatory=$true)]
  [string]$role
)

$PW_LENGTH=10
$MAILDATABASEHIGH="Mailbox Database High"
$MAILDATABASEMEDIUM="Mailbox Database Medium"
$MAILDATABASELOW="Mailbox Database Low01"
$STDGROUPS="stdgroups.txt"

# Generate email address by appending @careconnect.org.au
$emailAddress=$accountName.toLower()+"@careconnect.org.au"

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
  $lowercase=[char[]]([char]'a'..[char]'k') # Lowercase
  $lowercase+=[char[]]([char]'m'..[char]'z') # exclude 'l'
  
  $uppercase=@()
  $uppercase=[char[]]([char]'A'..[char]'H') # Uppercase
  $uppercase+=[char[]]([char]'J'..[char]'Z') # exclude 'I'
  
  $number=@()
  $number=[char[]]([int][char]'0'..[int][char]'9') # Numerical
  $symbol=@()
  $symbol=[char[]]([int][char]'-'..[char]'!') # Symbols

  $TempPassword+=($uppercase | GET-RANDOM) # Single uppercase character
  $TempPassword+=($number | GET-RANDOM) # Single numerical character
  $TempPassword+=($symbol | GET-RANDOM) # Single symbolic character
  
  For ($loop=1; $loop –le ($PW_LENGTH-3); $loop++) { # Fill with lowercase characters
    $TempPassword+=($lowercase | GET-RANDOM)
  }
  
  $TempPassword = Shuffle-String($TempPassword)
  
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
$validLocations = "abbotsford","ballina","banyo","bella vista","bendigo","dandenong","diverse","doncaster","east brighton","echuca","moonee ponds","tweed heads"
if (($validLocations -contains $location) -eq $false) {
  write-host "!!!" $location "is an invalid location !!! " -foregroundcolor "red"
  break
}

# Exit if role is invalid
$role = $role.toLower()
$validRoles = "casemanager", "admin"
if (($validRoles -contains $role) -eq $false) {
  write-host "!!!" $role "is an invalid role !!! " -foregroundcolor "red"
  break
}

#Check that the command is running from the Exchange Management Shell
if (!(Get-Command get-exchangeserver -errorAction SilentlyContinue))
{
	Write-Host "Run this script from the Exchange Management Shell" -foregroundcolor "Red"
	#Break
}
	
#####################################
# Main
#####################################

# Set variables
$locationPath = "OU=" + $location + ",OU=Locations,OU=Careconnect,DC=CConnect,DC=local"
$groupsFile = "locations/" + $location + ".txt"
$roleFile = "roles/" + $role + ".txt"
$homeDrive = "H"
$homeDriveColon = $homeDrive + ":"
$homeDirectory = "\\ccnfnp01\userdata\" + $accountName
$UPN = $accountName + "@careconnect.org.au"

Import-Module ActiveDirectory

# Generate password
$Password = Get-TempPassword

# Create AD account
write-Host "Creating " $accountName "..."
New-ADUser -sAMAccountName $accountName `
           -Name $($firstName + " " + $lastName) `
 		   -GivenName $firstName `
		   -Surname $lastName `
		   -AccountPassword $(ConvertTo-SecureString $Password -AsPlainText -Force) `
		   -Path $locationPath `
		   -OtherAttributes @{mail=$emailAddress} `
		   -HomeDrive $homeDrive `
		   -HomeDirectory $homeDirectory `
		   -UserPrincipalName $UPN `
		   -Enable $true

# Set RDS HomeDrive
$userDN = (Get-ADUser $accountName).distinguishedName
$userInfo = [ADSI]"LDAP://$userDN"
$userinfo.invokeset('terminalserviceshomedrive',$homeDriveColon)
$userinfo.invokeset('terminalserviceshomedirectory',$homeDirectory)
$userinfo.setinfo()

# Add account to every group in STDGROUPS file
foreach ($group in (get-content $STDGROUPS)) {
  Add-ADGroupMember -Identity $group -Members $accountName
}
	
# Add account to every group in groupsFile
foreach ($group in (get-content $groupsFile)) {
  Add-ADGroupMember -Identity $group -Members $accountName
}

# Add account to every group in roleFile
foreach ($group in (get-content $roleFile)) {
  Add-ADGroupMember -Identity $group -Members $accountName
}



# Create Exchange mailbox and enable it
$mailDatabase = get-UserMailDatabase
write-Host "Creating mailbox on" $mailDatabase
Enable-Mailbox $accountName -Database "$mailDatabase"

# Inform user of success
write-Host "Account created successfully."
echo $Password | clip
write-Host "Password has been sent to the clipboard."

write-host "Remember to add user to Policy Patrol and WebMarshal!" -foregroundcolor "yellow"