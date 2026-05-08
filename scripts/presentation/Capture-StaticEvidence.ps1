[CmdletBinding()]
param(
  [switch]$FailOnMissingBrowser
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$OutDir = Join-Path $RepoRoot "docs/presentation/screenshots"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$Roots = @(
  $env:ProgramFiles,
  [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

$Candidates = New-Object System.Collections.Generic.List[string]

foreach ($Root in $Roots) {
  $Candidates.Add((Join-Path $Root "Microsoft/Edge/Application/msedge.exe")) | Out-Null
  $Candidates.Add((Join-Path $Root "Google/Chrome/Application/chrome.exe")) | Out-Null
}

$Browser = $Candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $Browser) {
  $Message = "No local Edge/Chrome executable found. Screenshot capture skipped."
  if ($FailOnMissingBrowser) {
    throw $Message
  }

  Write-Warning $Message
  exit 0
}

function Capture-Page {
  param(
    [string]$InputPath,
    [string]$OutputName,
    [string]$WindowSize = "1440,2200"
  )

  $InputFull = (Resolve-Path (Join-Path $RepoRoot $InputPath)).ProviderPath
  $OutputFull = Join-Path $OutDir $OutputName
  $Uri = (New-Object System.Uri($InputFull)).AbsoluteUri

  $Args = @(
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    "--window-size=$WindowSize",
    "--screenshot=$OutputFull",
    $Uri
  )

  & $Browser @Args | Out-Null

  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $OutputFull)) {
    throw "Screenshot failed for $InputPath"
  }

  Write-Host "[shot] $OutputFull"
}

Capture-Page -InputPath "docs/presentation/evidence-gallery.html" -OutputName "evidence-gallery.png"
Capture-Page -InputPath "audit/demo_audit/report.html" -OutputName "report-html.png"

Write-Host "[OK] static evidence screenshots captured"
