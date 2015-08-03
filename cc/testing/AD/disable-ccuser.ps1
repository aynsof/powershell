###
#Usage: ./userdisable.ps1 <username> or run without parameters and it will prompt for the username
#Creates by: James Kingsmill
#Version: 1.0
#Date: 07/10/2014
###

#Get UserName
param(
    [Parameter(Mandatory = $true,
                    Position = 0)]
    [String]
    $AccountToDisable
    )
#Load ActiveDirectory Module
If (!(Get-module ActiveDirectory )) 
{
    write-host "Loading Active Directory modules" -foregroundcolor "green"
    Import-Module ActiveDirectory
}

$HOMEPATH = "\\ccnfnp01\userdata$\" + $AccountToDisable
$CITRIXPATH = "\\ccnxprnt-prod01\CitrixUPMProfiles$\" + $AccountToDisable
$TEMPMAILPATH = "\\ccnexch03\temp\" + $AccountToDisable
$HOMEARCHIVEPATH = "\\abbotssynology1\HomeDrives\Archived Home Drives\" + $AccountToDisable
$MAILARCHIVEPATH = "\\abbotssynology1\ExportedMailboxes\Archived Mailboxes\"

#Check if username exists
$User = $(try {get-aduser -identity $AccountToDisable} catch {$null})
If ($User -eq $Null)
{
    cls
    write-host "!!! Username" $AccountToDisable "Does not exist!!! " -foregroundcolor "red"
}
else
{
    #Set date as variable
    $date = Get-Date -format "yyyy-MM"

	cls
	write-host "Processing the account" $AccountToDisable "for archive and disabling" -foregroundcolor "green"

	#Create Archive Path
	if(!(Test-Path -Path $HOMEARCHIVEPATH))
	{
	new-item -path $HOMEARCHIVEPATH -type directory | out-null
	write-host "* Created Archive folder" $HOMEARCHIVEPATH -foregroundcolor "green"
	}
	else
	{
	write-host "!!! Archive path already exists !!!" -foregroundcolor "red"
	}

##################################
#	Exchange
##################################

	#Check that the command is running from the Exchange Management Shell
	if (!(Get-Command get-exchangeserver -errorAction SilentlyContinue))
	{
	Write-Host "!!! Run this script from the Exchange Management Shell !!!" -foregroundcolor "Red"
	Break
	}
	connect-exchangeserver -auto

	#Remove Activesync Access
	IF ((Get-CASMailbox $AccountToDisable | where-object {$_.ActiveSyncEnabled -eq $true})) 
	{
	Set-CASMailbox -Identity $AccountToDisable -ActiveSyncEnabled $false
	write-host "* Disabled Activesync for" $AccountToDisable -foregroundcolor "green"
	}
	else
	{
	write-host "* Activesync already disabled for" $AccountToDisable -foregroundcolor "green"
	}

	#Mailbox Archive

	IF ((get-mailbox -identity $AccountToDisable -ErrorAction SilentlyContinue))
	{
	    $MailboxPerms = $MAILARCHIVEPATH + $AccountToDisable + "-Mailbox-" + $date + ".csv"
	    $MailboxExport = $TEMPMAILPATH + "-" + $date + ".pst"
	    #Exports mailbox permissions
	    Get-MailboxPermission -identity $AccountToDisable | where-object {$_.Deny -eq $False -and $_.IsInherited -eq $False} | select-object User,{$_.Accessrights},InheritanceType |export-csv -path $MailboxPerms -notypeinformation

	    #Archive Mailbox
	    $Batchname = $AccountToDisable + "-" + $date
	    New-MailboxExportRequest -mailbox $AccountToDisable -filepath $MailboxExport -BatchName $BatchName -ErrorAction Stop

    	#Wait for mailbox export to complete
    	while ((Get-MailboxExportRequest -BatchName $BatchName | Where {$_.Status -eq "Queued" -or $_.Status -eq "InProgress"}))
    	{
    	    write-host "Waiting for Mailbox export to complete, waiting 60 seconds" -foregroundcolor "green"
    	    Get-MailboxExportRequest -BatchName $BatchName | Get-MailboxExportRequestStatistics | select-object Batchname,Status,PercentComplete
    	    sleep 60
    	}
    	#Checks to make sure that the export doesnt fail
    	while ((Get-MailboxExportRequest -BatchName $BatchName | Where {$_.Status -eq "Failed"}))
    	{
    	    write-host "!!! Mailbox export failed !!!" -foregroundcolor "Red"
    	    Break
    	}

    	# Move mailbox to archive server
    	move-item $MailboxExport $MAILARCHIVEPATH
    	write-host "* User Drive archived to $MAILARCHIVEPATH" -foregroundcolor "green"

    	#Disable Mailbox
    	Disable-Mailbox -Identity $AccountToDisable -Confirm:$false
    	}
    else
    {
    	write-host "!!! Mailbox for" $AccountToDisable "not found !!!" -foregroundcolor "red"
    	"!!! Mailbox Not Found !!!" | out-file $mailboxtarget
    }
	

##################################
#	AD Account
##################################

	# Move to "Disabled Users" OU
	Get-ADUser $AccountToDisable| Move-ADObject -TargetPath 'OU=Disabled Users,OU=Careconnect,DC=CConnect,DC=local'
	write-host "*" $AccountToDisable "moved to Disabled Users OU" -foregroundcolor "green"
	
	# Disable user
	$Disabled = Get-Aduser $AccountToDisable
	if ($Disabled.enabled -eq $true)
	{
	    Disable-ADAccount -Identity $AccountToDisable
	    write-host "*** " $AccountToDisable "account has been disabled ***" -foregroundcolor "green"
	}

	# Remove user from groups
	$GroupsToRemove =(Get-ADUser $AccountToDisable -Properties memberof | select -expand memberof)
	foreach($item in $GroupsToRemove){Remove-ADGroupMember $AccountToDisable -Identity $item -Confirm:$False}
	write-host "* Group Memberships Removed" -foregroundcolor "green"

##################################
#	File shares
##################################

	#move home drive to archive
	IF(test-path $HOMEPATH)
	{
	    robocopy $HOMEPATH $HOMEARCHIVEPATH /MOVE /S | out-null
	    write-host "* User Drive archived to $HOMEARCHIVEPATH" -foregroundcolor "green"
	}
	else
	{
	    write-host "!!! No User Drive to Archive !!!" -foregroundcolor "red"
	}
	
	# Delete Citrix UPM Profile
	If(test-path $CITRIXPATH)
	{
	    get-childitem $CITRIXPATH -recurse | remove-item -recurse -confirm:$false -force
        # Use CMD to get around 260 char limit
        cmd /C "rmdir /S /Q $CITRIXPATH"
	
	}


    # Remember to delete the user from Policy Patrol
	write-host "!!! Remember to delete the user from Policy Patrol !!!" -foregroundcolor "yellow"
}