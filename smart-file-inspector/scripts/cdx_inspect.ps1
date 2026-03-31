\
param(
  [Parameter(Mandatory=$true)][string]$File,
  [string]$Profile="auto",
  [string]$ConfigPath="$PSScriptRoot\..\config\profiles.json"
)

function Load-Config($path) {
  Get-Content $path -Raw | ConvertFrom-Json
}

function Guess-Profile($file) {
  $ext = [IO.Path]::GetExtension($file).ToLowerInvariant()
  if ($ext -in @(".log",".txt")) { return "log" }
  if ($ext -in @(".md")) { return "markdown" }
  if ($ext -in @(".cs",".js",".ts",".go",".py",".java",".cpp",".c",".h",".hpp",".json",".yaml",".yml",".xml",".sql",".ps1",".sh")) { return "code" }
  return "auto"
}

$cfg = Load-Config $ConfigPath
$fi = Get-Item -LiteralPath $File -ErrorAction Stop

# Read head bytes for text-likeness
$headLen = [Math]::Min(4096, $fi.Length)
$bytes = [byte[]]::new($headLen)
$fs = [System.IO.File]::OpenRead($fi.FullName)
$null = $fs.Read($bytes, 0, $bytes.Length)
$fs.Close()

$printable = 0
foreach ($b in $bytes) {
  if (($b -ge 9 -and $b -le 13) -or ($b -ge 32 -and $b -le 126)) { $printable++ }
}
$ratio = if ($bytes.Length -gt 0) { [Math]::Round($printable / $bytes.Length, 3) } else { 0.0 }

# Choose profile
if ($Profile -eq "auto") { $Profile = Guess-Profile $fi.FullName }
if ($Profile -eq "auto" -and $ratio -lt 0.70) { $Profile = "binary" }
elseif ($Profile -eq "auto") { $Profile = "httptrace" } # unknown but text-like: treat as trace-ish

$hash = ""
try { $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $fi.FullName).Hash } catch { $hash = "" }

[pscustomobject]@{
  path = $fi.FullName
  sizeBytes = $fi.Length
  lastWriteTime = $fi.LastWriteTime
  sha256 = $hash
  printableRatio = $ratio
  profile = $Profile
} | ConvertTo-Json -Depth 4
