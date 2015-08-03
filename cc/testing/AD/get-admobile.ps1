param(
  [string]$mobile = $(throw "missing number")
)

get-aduser -filter {mobile -like $mobile} -properties name,mobile | select-object name,mobile