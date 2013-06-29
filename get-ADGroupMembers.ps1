## Get the active users of an AD group - return their username and fullname

add-pssnapin quest.activeroles.admanagement

Connect-QADService domain.com

Get-QADGroupMember domain\groupname

Get-QADGroupMember domain\groupname | Get-QADUser -enabled

Get-QADGroupMember domain\groupname | Get-QADUser -enabled | select-object name,displayname
