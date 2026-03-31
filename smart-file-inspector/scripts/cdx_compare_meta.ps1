\
param(
  [Parameter(Mandatory=$true)][string]$FileA,
  [Parameter(Mandatory=$true)][string]$FileB
)

function Meta($f) {
  $fi = Get-Item -LiteralPath $f -ErrorAction Stop
  $h = ""
  try { $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $fi.FullName).Hash } catch { $h = "" }
  [pscustomobject]@{ path=$fi.FullName; sizeBytes=$fi.Length; lastWriteTime=$fi.LastWriteTime; sha256=$h }
}

$a = Meta $FileA
$b = Meta $FileB

[pscustomobject]@{
  A = $a
  B = $b
  sameHash = ($a.sha256 -ne "" -and $a.sha256 -eq $b.sha256)
  sizeDeltaBytes = ($a.sizeBytes - $b.sizeBytes)
} | ConvertTo-Json -Depth 5
