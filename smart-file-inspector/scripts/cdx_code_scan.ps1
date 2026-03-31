\
param(
  [Parameter(Mandatory=$true)][string]$File,
  [int]$MaxItems=60,
  [int]$MaxEvidence=12
)

$fi = Get-Item -LiteralPath $File -ErrorAction Stop

$classes = @{}
$methods = @{}
$usings = @{}
$urls = @{}
$evidence = New-Object System.Collections.Generic.List[object]

$classRegex = [regex]'\b(class|struct|interface)\s+([A-Za-z_][A-Za-z0-9_]*)'
$methodRegex = [regex]'\b([A-Za-z_][A-Za-z0-9_]*)\s*\('
$usingRegex = [regex]'^\s*using\s+([A-Za-z0-9_\.]+)\s*;'
$urlRegex = [regex]'https?://[^\s"''<>]{8,200}'

$i = 0
Get-Content -Path $fi.FullName -ReadCount 1 -ErrorAction Stop | ForEach-Object {
  $i++
  $ln = $_

  $u = $usingRegex.Match($ln)
  if ($u.Success) {
    $k = $u.Groups[1].Value
    if (-not $usings.ContainsKey($k)) { $usings[$k]=0 }
    $usings[$k]++
  }

  $c = $classRegex.Match($ln)
  if ($c.Success) {
    $k = $c.Groups[2].Value
    if (-not $classes.ContainsKey($k)) { $classes[$k]=0 }
    $classes[$k]++
    if ($evidence.Count -lt $MaxEvidence) { $evidence.Add([pscustomobject]@{ line=$i; kind="class"; preview=$ln.Trim() }) }
  }

  # method heuristic: avoid keywords
  if ($ln -match '\(') {
    $m = $methodRegex.Match($ln)
    if ($m.Success) {
      $name = $m.Groups[1].Value
      if ($name -notin @("if","for","while","switch","catch","return","new","using","nameof")) {
        if (-not $methods.ContainsKey($name)) { $methods[$name]=0 }
        $methods[$name]++
      }
    }
  }

  $um = $urlRegex.Match($ln)
  if ($um.Success) {
    $v = $um.Value
    if (-not $urls.ContainsKey($v)) { $urls[$v]=0 }
    $urls[$v]++
  }
}

$topClasses = $classes.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $MaxItems | ForEach-Object { @{ name=$_.Key; count=$_.Value } }
$topMethods = $methods.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $MaxItems | ForEach-Object { @{ name=$_.Key; count=$_.Value } }
$topUsings  = $usings.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $MaxItems | ForEach-Object { @{ ns=$_.Key; count=$_.Value } }
$topUrls    = $urls.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 30 | ForEach-Object { @{ url=$_.Key; count=$_.Value } }

[pscustomobject]@{
  file = $fi.FullName
  sizeBytes = $fi.Length
  classes = $topClasses
  methods = $topMethods
  usings = $topUsings
  urls = $topUrls
  evidence = $evidence
} | ConvertTo-Json -Depth 8
