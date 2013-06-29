<#
.SYNOPSIS
	Adds OUs and groups to UNIX OU in Active Directory
.DESCRIPTION
	Lists existing OUs in the UNIX OU, then creates new OUs if necessary.  Prompts for names of new servers, and for GIDs, then creates the appropriate groups.  (Note: GIDs MUST be created in the User Register at dew.bom.gov.au/reg/protected/reg_group.php before running this script.)
.NOTES
	Author		: James Kingsmill - j.kingsmill@bom.gov.au
.LINK
	cwd_ops@bom.gov.au
#>

# Maximum length of computer account name
$SERVER_MAXLEN = 15

# Import modules
add-pssnapin quest.activeroles.admanagement
Import-Module ActiveDirectory


Function Prewarn-Users
# Warn users to create GIDs before proceeding
{
  echo "This script requires you to have generated GIDs in the User Register (dew.bom.gov.au/reg/protected/reg_group.php)."
  echo ""
  echo "GIDs start at 5000."
  echo ""
  echo "Ensure you have generated these GIDs before proceeding.  Press any key to continue."
  $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Function Get-Project
# List projects in the UNIX_Groups OU
# Ask for input
# Create project OU if it doesn't exist
{
  Write-Host "Existing projects in the UNIX_Groups OU:"
  get-qadobject -type organizationalunit -SearchScope OneLevel -searchRoot "OU=UNIX_Groups,OU=UNIX,dc=bom,dc=gov,dc=au" |%{$_.name} | Write-Host

  # Select a project
  $current_project = Read-Host 'Enter a project name'
  
  # If the entered project doesn't exist, create it
  if (!(get-qadobject -type organizationalunit -SearchScope OneLevel -searchRoot "OU=UNIX_Groups,OU=UNIX,dc=bom,dc=gov,dc=au" -name $current_project))
  {
    Write-Host "Creating project ${current_project}."

	# Create the project
    New-QADObject -type OrganizationalUnit -Name $current_project -ParentContainer "OU=UNIX_Groups,OU=UNIX,dc=bom,dc=gov,dc=au" | Out-Null
  }
  
  # Return the selected project
  $current_project
}

Function Get-Environment ( $current_project )
# List environments within the $current_project OU
# Ask for input
# Create environment OU if it doesn't exist
{
  Write-Host "Existing environments in the ${current_project} OU:"
  get-qadobject -type organizationalunit -SearchScope OneLevel -searchRoot "OU=$current_project,OU=UNIX_Groups,OU=UNIX,dc=bom,dc=gov,dc=au" |%{$_.name} | Write-Host

  $current_environment = Read-Host 'Enter an environment'

  # If the entered environment doesn't exist, create it
  if (!(get-qadobject -type organizationalunit -SearchScope OneLevel -searchRoot "OU=$current_project,OU=UNIX_Groups,OU=UNIX,dc=bom,dc=gov,dc=au" -name $current_environment))
  {
    Write-Host "Creating environment ${current_environment}."
    New-QADObject -type OrganizationalUnit -Name $current_environment -ParentContainer "OU=$current_project,OU=UNIX_Groups,OU=UNIX,dc=bom,dc=gov,dc=au" | Out-Null
  }
	
  $current_environment
}

Function Create-ProjEnvGroups ( $current_project, $current_environment )
# Create _access and _admin groups for the given project and environment
{
	# Group names for project/environment 'access' and 'admin'
	$proj_env_access = "cwd_" + $current_project + "_" + $current_environment + "_access"
	$proj_env_admin = "cwd_" + $current_project + "_" + $current_environment + "_admin"

	# Linux expects the group names to be in lower case
	$proj_env_access = $proj_env_access.ToLower()
	$proj_env_admin = $proj_env_admin.ToLower()

	# Does the _access group already exist?
	if (!(get-qadobject -type Group -SearchScope OneLevel -searchRoot "OU=$current_environment,OU=$current_project,OU=UNIX_Groups,OU=UNIX,dc=bom,dc=gov,dc=au" -name $proj_env_access))
	{
	  # Get GID
	  $access_gid = Read-Host "Enter UserReg GID for group ${proj_env_access}"

	  # Create _access group
	  New-QADObject -type Group -Name $proj_env_access -ParentContainer "OU=$current_environment,OU=$current_project,OU=UNIX_Groups,OU=UNIX,dc=bom,dc=gov,dc=au" -ObjectAttributes @{msSFU30NisDomain="bom"; gidNumber=$access_gid; sAMAccountName=$proj_env_access} | Out-Null
	}
	  
	# Does the _admin group already exist?
	if (!(get-qadobject -type Group -SearchScope OneLevel -searchRoot "OU=$current_environment,OU=$current_project,OU=UNIX_Groups,OU=UNIX,dc=bom,dc=gov,dc=au" -name $proj_env_admin))
	{
	  # Get GID
	  $admin_gid = Read-Host "Enter UserReg GID for group ${proj_env_admin}"

	  # Create _access group
	  New-QADObject -type Group -Name $proj_env_admin -ParentContainer "OU=$current_environment,OU=$current_project,OU=UNIX_Groups,OU=UNIX,dc=bom,dc=gov,dc=au" -ObjectAttributes @{msSFU30NisDomain="bom"; gidNumber=$admin_gid; sAMAccountName=$proj_env_admin} | Out-Null
	}
}

Function Create-ComputerAccount ( $server_name )
# Create a computer account and associated SPN and keytab file
{
	# Trim the server name to whichever is shorter: SERVER_MAXLEN, or the length of the string
	$server_name_trimmed = $server_name.substring(0, [System.Math]::Min($SERVER_MAXLEN, $server_name.Length))

	# Create computer account
	New-QADObject -type Computer -Name $server_name -ParentContainer "OU=UNIX_Hosts,OU=UNIX,dc=bom,dc=gov,dc=au" -ObjectAttributes @{sAMAccountName=$server_name_trimmed} | Out-Null
	
	# Create the SPN
	setspn -A host/$server_name_trimmed.bom.gov.au@BOM.GOV.AU $server_name
	
	# Create the keytab for the server
	if (ktpass /princ host/$server_name_trimmed.bom.gov.au@BOM.GOV.AU /out C:\$server_name.keytab /crypto all /ptype KRB5_NT_PRINCIPAL -desonly /mapuser BOM\$server_name_trimmed +rndPass)
	{
		Write-Host "Keytab created at C:\${server_name}.keytab."
		Write-Host "Remember to copy this file to your Linux server securely, then delete this local copy."
	}
	else
	{
		Write-Host "Keytab creation unsuccessful."
	}
}

Function Get-Servers ( $current_project, $current_environment )
# Get list of servers
# Create _access and _admin groups for them
# Create computer accounts for them
{
	# Group names for project/environment 'access' and 'admin'
	$proj_env_access = "cwd_" + $current_project + "_" + $current_environment + "_access"
	$proj_env_admin = "cwd_" + $current_project + "_" + $current_environment + "_admin"

	# Ask for list of servers
	$servers = Read-Host 'Enter the list of servers, separated by commas'
	$servers = $servers.split(",")

	# Create 'access' and 'admin' groups for each server
	$servers |%{ 
		$server_name = $_
		$server_access = $_ + "_access"
		$server_admin = $_ + "_admin"

		# Ensure in lower case
		$server_access = $server_access.ToLower()
		$server_admin = $server_admin.ToLower()

		# Get GIDs for server groups
		$access_gid = Read-Host "Enter UserReg GID for group ${server_access}"
		$admin_gid = Read-Host "Enter UserReg GID for group ${server_admin}"

		Write-Host "Creating groups..."		

		# Create _access and _admin groups and get DNs for them
		$server_access_dn = New-QADObject -type Group -Name $server_access -ParentContainer "OU=$current_environment,OU=$current_project,OU=UNIX_Groups,OU=UNIX,dc=bom,dc=gov,dc=au" -ObjectAttributes @{msSFU30NisDomain="bom"; gidNumber=$access_gid; sAMAccountName=$server_access} | %{$_.dn}
		$server_admin_dn = New-QADObject -type Group -Name $server_admin -ParentContainer "OU=$current_environment,OU=$current_project,OU=UNIX_Groups,OU=UNIX,dc=bom,dc=gov,dc=au" -ObjectAttributes @{msSFU30NisDomain="bom"; gidNumber=$admin_gid; sAMAccountName=$server_admin} | %{$_.dn}
		
		# Waiting for AD replication to occur.  Can we do this more gracefully?
		Write-Host "Waiting for AD replication..."
		for ($i=10; $i -gt 0; $i--) { start-sleep -s 1;}
		
		# Ensure the group additions have been replicated
		get-adgroup $server_access | Out-Null
		get-adgroup $server_admin | Out-Null
		
		# Get DNs for project/environment groups
		$proj_env_access_dn = get-adgroup $proj_env_access | %{$_.DistinguishedName}
		$proj_env_admin_dn = get-adgroup $proj_env_admin | %{$_.DistinguishedName}
		
		# Establish group membership using DNs
		Add-ADGroupMember -Identity $server_access_dn -Members $proj_env_access_dn  | Out-Null
		Add-ADGroupMember -Identity $server_admin_dn -Members $proj_env_admin_dn  | Out-Null
		
		Create-ComputerAccount $server_name
		
	}
}


# Main section of script

PreWarn-Users

$current_project = Get-Project

$current_environment = Get-Environment $current_project

Create-ProjEnvGroups $current_project $current_environment

Get-Servers $current_project $current_environment





remove-pssnapin quest.activeroles.admanagement

