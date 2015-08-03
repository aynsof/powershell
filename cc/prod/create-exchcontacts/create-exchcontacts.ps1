###
#Usage: ./create-exchcontacts.ps1 <accountlist> - expects a newline-separated txt file of the format "FirstName LastName,email@address.com"
#Created by: James Kingsmill
#Purpose: Bulk creation of Exchange contacts.  Adds each new contact to an existing Distribution List.
#Version: 1.0
#Date: 09/10/2014
###


#Get AccountList
param(
    [Parameter(Mandatory = $true,
                    Position = 0)]

  [string]$AccountList = $(throw "missing account list"),
  [string]$DistributionList = $(throw "missing distribution list")
)

$users = gc $AccountList
foreach ($user in $users) {
  $user = $user.split(",")
  
  $name = $user[0]
  $email = $user[1]

  New-MailContact -Name "$name" -ExternalEmailAddress $email -OrganizationalUnit "Contacts"
  Add-DistributionGroupMember -identity "$DistributionList" -member "$name"
}