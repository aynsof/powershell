write-host installing nxlog
copy "\\abbotssynology1\Software\Apps\nxlog\nxlog-ce-2.8.1248.msi" "C:\Program Files (x86)\"
msiexec /passive /i "C:\Program Files (x86)\nxlog-ce-2.8.1248.msi"
start-sleep -s 5
write-host copying configuration
move "C:\Program Files (x86)\nxlog\conf\nxlog.conf" "C:\Program Files (x86)\nxlog\conf\nxlog.conf.default"
copy "\\abbotssynology1\Software\Apps\nxlog\nxlog.conf" "C:\Program Files (x86)\nxlog\conf\nxlog.conf"
write-host starting service
net start nxlog
rm 'C:\Program Files (x86)\nxlog-ce-2.8.1248.msi'
write-host done
