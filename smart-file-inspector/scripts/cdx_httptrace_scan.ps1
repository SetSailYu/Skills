\
param(
  [Parameter(Mandatory=$true)][string]$File,
  [int]$MaxEvidence=12
)

$fi = Get-Item -LiteralPath $File -ErrorAction Stop

# Scan line-by-line; detect request/response markers and collect distributions.
$reqDist = @{}       # "GET /path" or "POST /path"
$statusDist = @{}    # status codes
$cookieSet = @{}     # set-cookie names
$hostDist = @{}      # Host values
$evidence = New-Object System.Collections.Generic.List[object]

# heuristics
$reqRegex = [regex]'^\s*(GET|POST|PUT|DELETE|PATCH)\s+([^\s]+)'
$statusRegex = [regex]'\bHTTP\/\d\.\d\s+(\d{3})\b'
$hostRegex = [regex]'^\s*Host:\s*([^\s]+)'
$setCookieRegex = [regex]'^\s*Set-Cookie:\s*([^=;,\s]+)='

$i = 0
Get-Content -Path $fi.FullName -ReadCount 1 -ErrorAction Stop | ForEach-Object {
  $i++
  $ln = $_

  $m = $reqRegex.Match($ln)
  if ($m.Success) {
    $k = ($m.Groups[1].Value + " " + $m.Groups[2].Value)
    if (-not $reqDist.ContainsKey($k)) { $reqDist[$k]=0 }
    $reqDist[$k]++
    if ($evidence.Count -lt $MaxEvidence) {
      $evidence.Add([pscustomobject]@{ line=$i; kind="request"; preview=$k })
    }
  }

  $s = $statusRegex.Match($ln)
  if ($s.Success) {
    $c = $s.Groups[1].Value
    if (-not $statusDist.ContainsKey($c)) { $statusDist[$c]=0 }
    $statusDist[$c]++
    if ($evidence.Count -lt $MaxEvidence) {
      $evidence.Add([pscustomobject]@{ line=$i; kind="status"; preview=("HTTP " + $c) })
    }
  }

  $h = $hostRegex.Match($ln)
  if ($h.Success) {
    $hv = $h.Groups[1].Value
    if (-not $hostDist.ContainsKey($hv)) { $hostDist[$hv]=0 }
    $hostDist[$hv]++
  }

  $sc = $setCookieRegex.Match($ln)
  if ($sc.Success) {
    $cn = $sc.Groups[1].Value
    if (-not $cookieSet.ContainsKey($cn)) { $cookieSet[$cn]=0 }
    $cookieSet[$cn]++
    if ($evidence.Count -lt $MaxEvidence) {
      $evidence.Add([pscustomobject]@{ line=$i; kind="set-cookie"; preview=("Set-Cookie " + $cn) })
    }
  }
}

$topReq = $reqDist.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 30 | ForEach-Object { @{ req=$_.Key; count=$_.Value } }
$topStatus = $statusDist.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | ForEach-Object { @{ code=$_.Key; count=$_.Value } }
$topHosts = $hostDist.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10 | ForEach-Object { @{ host=$_.Key; count=$_.Value } }
$topCookies = $cookieSet.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 30 | ForEach-Object { @{ name=$_.Key; count=$_.Value } }

[pscustomobject]@{
  file = $fi.FullName
  sizeBytes = $fi.Length
  requests = $topReq
  statusCodes = $topStatus
  hosts = $topHosts
  setCookieNames = $topCookies
  evidence = $evidence
} | ConvertTo-Json -Depth 8
