\
param(
  [Parameter(Mandatory=$true)][string]$File,
  [string]$Query="",
  [int]$MaxEvidence=12,
  [int]$TopTokens=20,
  [int]$MaxTokenLen=32
)

$fi = Get-Item -LiteralPath $File -ErrorAction Stop

# quick text-likeness check (avoid binary fullscan)
$headLen = [Math]::Min(4096, $fi.Length)
$head = [byte[]]::new($headLen)
$fs = [System.IO.File]::OpenRead($fi.FullName)
$null = $fs.Read($head, 0, $head.Length)
$fs.Close()

$printable = 0
foreach ($b in $head) {
  if (($b -ge 9 -and $b -le 13) -or ($b -ge 32 -and $b -le 126)) { $printable++ }
}
$ratio = if ($head.Length -gt 0) { $printable / $head.Length } else { 0 }
if ($ratio -lt 0.70) {
  [pscustomobject]@{
    file = $fi.FullName
    sizeBytes = $fi.Length
    printableRatio = [Math]::Round($ratio,3)
    error = "Binary-like file. Use cdx_inspect.ps1 / binary strategy instead of fullscan."
  } | ConvertTo-Json -Depth 6
  exit 0
}

$lineCount = 0
$matchCount = 0
$evidence = New-Object System.Collections.Generic.List[object]

$levelDist = @{}
$codeDist  = @{}
$tokenDist = @{}

$stop = @{"the"=1;"and"=1;"for"=1;"with"=1;"this"=1;"that"=1;"from"=1;"http"=1;"https"=1;"null"=1;"true"=1;"false"=1}
$levelRegex = [regex]'\b(ERROR|WARN|WARNING|INFO|DEBUG|TRACE)\b'
$codeRegex  = [regex]'\b(\d{3})\b'
$qRegex = $null
if (-not [string]::IsNullOrWhiteSpace($Query)) { $qRegex = [regex]$Query }

$i = 0
Get-Content -Path $fi.FullName -ReadCount 1 -ErrorAction Stop | ForEach-Object {
  $i++
  $lineCount++
  $ln = $_

  $m = $levelRegex.Match($ln)
  if ($m.Success) {
    $k = $m.Groups[1].Value
    if (-not $levelDist.ContainsKey($k)) { $levelDist[$k]=0 }
    $levelDist[$k]++
  }

  foreach ($cm in $codeRegex.Matches($ln)) {
    $c = $cm.Groups[1].Value
    if ($c -match '^(2|3|4|5)\d{2}$') {
      if (-not $codeDist.ContainsKey($c)) { $codeDist[$c]=0 }
      $codeDist[$c]++
    }
  }

  foreach ($t in [regex]::Matches($ln, '[A-Za-z_][A-Za-z0-9_\-]{2,}')) {
    $w = $t.Value.ToLowerInvariant()
    if ($w.Length -gt $MaxTokenLen) { continue }
    if ($stop.ContainsKey($w)) { continue }
    if (-not $tokenDist.ContainsKey($w)) { $tokenDist[$w]=0 }
    $tokenDist[$w]++
  }

  $hit = $false
  if ($qRegex -ne $null -and $qRegex.IsMatch($ln)) { $hit = $true; $matchCount++ }

  # evidence: query hits preferred; else first ERROR/WARN lines
  if ($hit -and $evidence.Count -lt $MaxEvidence) {
    $preview = $ln
    if ($preview.Length -gt 240) { $preview = $preview.Substring(0,240) + "…" }
    $evidence.Add([pscustomobject]@{ line=$i; preview=$preview })
  } elseif ($evidence.Count -lt $MaxEvidence -and $levelRegex.IsMatch($ln)) {
    $preview = $ln
    if ($preview.Length -gt 240) { $preview = $preview.Substring(0,240) + "…" }
    $evidence.Add([pscustomobject]@{ line=$i; preview=$preview })
  }
}

$topLevels = $levelDist.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10 | ForEach-Object { @{ key=$_.Key; count=$_.Value } }
$topCodes  = $codeDist.GetEnumerator()  | Sort-Object Value -Descending | Select-Object -First 15 | ForEach-Object { @{ key=$_.Key; count=$_.Value } }
$topTok    = $tokenDist.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $TopTokens | ForEach-Object { @{ token=$_.Key; count=$_.Value } }

[pscustomobject]@{
  file = $fi.FullName
  sizeBytes = $fi.Length
  printableRatio = [Math]::Round($ratio,3)
  lineCount = $lineCount
  query = $Query
  queryMatchCount = $matchCount
  topLevels = $topLevels
  topStatusCodes = $topCodes
  topTokens = $topTok
  evidence = $evidence
} | ConvertTo-Json -Depth 8
