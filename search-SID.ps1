## Provide a list of SIDs and you get their AD username

$a = get-resource C:\list_of_sids.txt

$a | get-qadgroup | select-object name,sid
