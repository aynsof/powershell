$PW_LENGTH=10

Function Get-TempPassword {
  # Generate string of valid characters
  $alphabet=@()
  $alphabet=[char[]]([int][char]'1'..[int][char]'Z')

  For ($loop=1; $loop –le $PW_LENGTH; $loop++) {
    $TempPassword+=($alphabet | GET-RANDOM)
  }

  return $TempPassword
}

$pw = Get-TempPassword
echo $pw