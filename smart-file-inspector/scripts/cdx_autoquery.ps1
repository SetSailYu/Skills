\
param(
  [Parameter(Mandatory=$true)][string]$File,
  [int]$MaxBytes=65536,
  [int]$TopK=12
)

$fi = Get-Item -LiteralPath $File -ErrorAction Stop
$len = [Math]::Min($MaxBytes, $fi.Length)
$bytes = [byte[]]::new($len)

$fs = [System.IO.File]::OpenRead($fi.FullName)
$null = $fs.Read($bytes, 0, $bytes.Length)
$fs.Close()

# Try UTF8 first; if many replacement chars, fallback ASCII
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
if (($text.ToCharArray() | Where-Object { $_ -eq [char]0xFFFD } | Measure-Object).Count -gt 50) {
  $text = [System.Text.Encoding]::ASCII.GetString($bytes)
}

$patterns = @(
  'https?://[^\s"''<>]{8,200}',
  '\/api\/[a-zA-Z0-9_\/\-\.]{3,120}',
  '[A-Za-z_][A-Za-z0-9_]{2,64}\.[A-Za-z_][A-Za-z0-9_]{2,64}',   # Namespace.Type
  '\b[A-Za-z_][A-Za-z0-9_]{2,64}\b',
  '\b\d{3}\b'                                                    # 3-digit codes like 406
)

$stop = @{"the"=1;"and"=1;"for"=1;"with"=1;"this"=1;"that"=1;"from"=1;"http"=1;"https"=1;"null"=1;"true"=1;"false"=1}
$bag = @{}

foreach ($p in $patterns) {
  foreach ($m in [regex]::Matches($text, $p)) {
    $w = $m.Value
    if ($w.Length -lt 3 -or $w.Length -gt 120) { continue }
    $lw = $w.ToLowerInvariant()
    if ($stop.ContainsKey($lw)) { continue }
    if (-not $bag.ContainsKey($w)) { $bag[$w] = 0 }
    $bag[$w]++
  }
}

$candidates = $bag.GetEnumerator() |
  Sort-Object @{Expression={ $_.Value }; Descending=$true}, @{Expression={ $_.Key.Length }; Descending=$true} |
  Select-Object -First ($TopK * 3)

$final = New-Object System.Collections.Generic.List[string]
foreach ($c in $candidates) {
  $w = $c.Key
  if ($w -match '^\d+$' -and $w -notmatch '^\d{3}$') { continue }
  if ($final.Count -ge $TopK) { break }
  $final.Add($w)
}

[pscustomobject]@{
  file = $fi.FullName
  topK = $TopK
  tokens = $final
} | ConvertTo-Json -Depth 4
