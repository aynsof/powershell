# Find all users in the Diverse OU
$users = get-aduser -filter * -searchbase "OU=Diverse,OU=Locations,OU=Careconnect,DC=CConnect,DC=Local"


foreach ($user in $users) {
  # For each user in the Diverse OU, set their attributes
  get-aduser $user | set-aduser -company "Diverse"
  get-aduser $user | set-aduser -department "Diverse"
  get-aduser $user | set-aduser -office "Bella Vista"
  get-aduser $user | set-aduser -city "Bella Vista"
  
  # Undo
  get-aduser $user | set-aduser -company $null
  get-aduser $user | set-aduser -department $null
  get-aduser $user | set-aduser -office $null
  get-aduser $user | set-aduser -city $null
  get-aduser $user | set-aduser -l $null
}