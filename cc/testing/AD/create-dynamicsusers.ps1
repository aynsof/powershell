# Import names
$userList = gc h:\powershell\dynamics-users.txt
# User password
$password='G0T3@mTe5t'
# Domain
$domain='cconnect.local'
# Container
$path = 'ou=Dynamics,ou=Service Accounts,dc=cconnect,dc=local'



function Trim-UserName($user) {

    if ($user.length -gt 18) {
      $trimmedname = $user.substring(0,18)

      return $trimmedname
    }
    else {
      return $user
    }

}

# New-ADUser
FOREACH ($user in $userList) {
    $concisename = Trim-UserName($user)
	echo $concisename
    $UPN = "$User@$domain"
    $Name =$user
    $enabled = $True
    $ADUserProps = @{
        'SamAccountName'    = $user;
        'DisplayName'       = $user;
        'AccountPassword'      = (ConvertTo-SecureString $password -AsPlainText -force);
        'UserPrincipalName' = $("$User@$Domain");
        'Name'              = $concisename;
        'Path'              = $path;
        'Enabled'           = $True
    }
    echo $user
    New-ADUser @ADUserProps
    #New-ADUser -SamAccountName $Username -DisplayName $Name -AccountPassword (ConvertTo-SecureString $password -AsPlainText -force) `
    #-UserPrincipalName $UPN -Name $Name -Path $path -Enabled $enabled -whatif
}
