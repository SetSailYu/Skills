\
param(
  [Parameter(Mandatory=$true)][string]$File,
  [int]$MaxItems=80
)

# Light key/value extractor: key=value or "key":"value"
$kvs = @{}
$lineNo = 0

Get-Content -Path $File -ReadCount 1 -ErrorAction Stop | ForEach-Object {
  $lineNo++
  $ln = $_

  if ($ln -match '(\b[a-zA-Z0-9_\-\.]{2,64})\s*=\s*([^\s,;]{1,200})') {
    $k = $matches[1]; $v=$matches[2]
    if (-not $kvs.ContainsKey($k)) { $kvs[$k]=$v }
  }
  if ($ln -match '"([a-zA-Z0-9_\-\.]{2,64})"\s*:\s*"([^"]{0,200})"') {
    $k = $matches[1]; $v=$matches[2]
    if (-not $kvs.ContainsKey($k)) { $kvs[$k]=$v }
  }
  if ($kvs.Count -ge $MaxItems) { return }
}

$kvs.GetEnumerator() | Sort-Object Name | ForEach-Object {
  [pscustomobject]@{ key=$_.Name; value=$_.Value }
} | ConvertTo-Json -Depth 4
