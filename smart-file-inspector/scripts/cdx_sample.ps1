\
param(
  [Parameter(Mandatory=$true)][string]$File,
  [int]$Head=60,
  [int]$Tail=60
)

"--- HEAD($Head) ---"
Get-Content -Path $File -TotalCount $Head -ErrorAction Stop
"--- TAIL($Tail) ---"
Get-Content -Path $File -Tail $Tail -ErrorAction Stop
