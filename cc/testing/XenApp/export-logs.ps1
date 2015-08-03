$date = get-date -format "yyyy-mm-dd"

#create dir
new-item -ItemType directory \\ccnfnp01\groupdata$\ICTDrive\Software\Dynamics\logs\$env:COMPUTERNAME-$date\

#copy DebugDiag logs to new dir
Copy-Item 'C:\Program Files\DebugDiag\Logs\*' \\ccnfnp01\groupdata$\ICTDrive\Software\Dynamics\logs\$env:COMPUTERNAME-$date\

#copy Application event log to new dir
wevtutil.exe epl Application \\ccnfnp01\groupdata$\ICTDrive\Software\Dynamics\logs\$env:COMPUTERNAME-$date\application.evtx