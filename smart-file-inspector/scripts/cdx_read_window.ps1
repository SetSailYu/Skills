\
param(
  [Parameter(Mandatory=$true)][string]$File,
  [Parameter(Mandatory=$true)][int]$Line,
  [int]$Before=60,
  [int]$After=60,
  [int]$MaxLines=200,
  [int]$MaxChars=20000
)

$start = [Math]::Max(1, $Line - $Before)
$end   = $Line + $After

$out = New-Object System.Collections.Generic.List[string]
$charCount = 0

$i = 0
Get-Content -Path $File -ReadCount 1 -ErrorAction Stop | ForEach-Object {
  $i++
  if ($i -ge $start -and $i -le $end) {
    $lineText = ("{0,7}: {1}" -f $i, $_)
    $out.Add($lineText)
    $charCount += $lineText.Length + 1
    if ($out.Count -ge $MaxLines) { break }
    if ($charCount -ge $MaxChars) { break }
  }
  if ($i -gt $end) { break }
}

$out
