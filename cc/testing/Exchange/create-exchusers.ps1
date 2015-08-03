###
#Usage: ./create-exchusers.ps1 <accountlist> - expects a newline-separated txt file of the format "FirstName LastName,email@address.com"
#Creates by: James Kingsmill
#Version: 1.0
#Date: 09/10/2014
###

#Get AccountList
param(
    [Parameter(Mandatory = $true,
                    Position = 0)]
    [String]
    $AccountList
    )

$users = gc $AccountList
foreach ($user in $users) {
  $user = $user.split(",")
  
  $name = $user[0]
  $email = $user[1]

  New-MailContact -Name "$name" -ExternalEmailAddress $email -OrganizationalUnit "Contacts"
  Add-DistributionGroupMember -identity "DCS Service Providers" -member "$name"
}