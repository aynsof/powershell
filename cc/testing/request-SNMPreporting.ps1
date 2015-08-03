$fromEmail = "it@careconnect.org.au"
$toEmail = "corporate-support@ticket.internode.com.au"
$cc = "jkingsmill@careconnect.org.au"

$subject = "SNMP logging and reporting"
$body = "Please provide SNMP logging and reporting for CareConnect."

$smtpServer = "ccnexch03.cconnect.local"

Send-MailMessage -from $fromEmail -to $toEmail -cc $cc -subject $subject -body $body -SmtpServer $smtpServer -DeliveryNotificationOption OnFailure