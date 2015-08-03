$users = "users.txt"
$GROUP = "ComPacks Team NNSW"

foreach ($user in (get-content $users)) {

  $accountIdentity = get-aduser -filter { displayName -eq $user }

  if ($accountIdentity -eq $Null) {
    write-host $user "not removed!!!" -foregroundcolor "red"
  }
  else {
    remove-ADGroupMember -Identity $GROUP -Members $accountIdentity -confirm:$false
    write-host $user "removed" 
  }
}
