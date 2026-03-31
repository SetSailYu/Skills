\
param(
  [Parameter(Mandatory=$true)][string]$Path,
  [string]$Query="",
  [string]$Profile="auto",
  [int]$MaxMatches=0,
  [string]$ConfigPath="$PSScriptRoot\..\config\profiles.json"
)

$cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$def = $cfg.defaults
if ($MaxMatches -le 0) { $MaxMatches = $def.maxMatches }

# If query empty -> use profile seeds as a weak query
if ([string]::IsNullOrWhiteSpace($Query)) {
  if ($Profile -eq "auto") { $Profile = "log" }
  $seeds = $cfg.profiles.$Profile.seed
  if ($seeds -and $seeds.Count -gt 0) {
    # escape for regex-ish OR query; rg supports regex, Select-String too
    $Query = ($seeds | ForEach-Object { [regex]::Escape($_) }) -join "|"
  } else {
    $Query = "."
  }
}

$results = @()
if (Get-Command rg -ErrorAction SilentlyContinue) {
  $results = rg -n --no-heading --color never $Query $Path | Select-Object -First $MaxMatches
} else {
  $results = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
    Select-String -Pattern $Query -ErrorAction SilentlyContinue |
    Select-Object -First $MaxMatches |
    ForEach-Object { "{0}:{1}:{2}" -f $_.Path, $_.LineNumber, $_.Line.Trim() }
}

$results | ForEach-Object {
  if ($_ -match "^(.*?):(\d+):(.*)$") {
    [pscustomobject]@{ file=$matches[1]; line=[int]$matches[2]; preview=$matches[3] }
  } else {
    [pscustomobject]@{ file=""; line=0; preview=$_ }
  }
} | ConvertTo-Json -Depth 4
