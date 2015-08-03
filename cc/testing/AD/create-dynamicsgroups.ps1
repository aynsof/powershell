# Import names
$groupList = gc h:\powershell\dynamics\groups.txt

$path = 'ou=Dynamics,ou=Security Groups,ou=Careconnect,dc=cconnect,dc=local'


FOREACH ($group in $groupList) {
  NEW-ADGroup –name $group –groupscope Global –path $path
}