[CmdletBinding()]
param(
  [string]$RepoRoot = "",
  [string]$OutDir = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
}

if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path $RepoRoot "audit/_latest/npm-audit-critical-threshold"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$JsonPath = Join-Path $OutDir "npm-audit-critical.json"
$TxtPath = Join-Path $OutDir "npm-audit-critical.txt"

Push-Location (Join-Path $RepoRoot "app")
try {
  $global:LASTEXITCODE = 0
  $Output = @(npm audit --audit-level=critical --json 2>&1)
  $ExitCode = [int]$global:LASTEXITCODE
  $Raw = ($Output | ForEach-Object { $_.ToString() }) -join "`n"

  if ([string]::IsNullOrWhiteSpace($Raw)) {
    throw "npm audit produced empty output"
  }

  Set-Content -Path $JsonPath -Value $Raw -Encoding UTF8

  try {
    $Audit = $Raw | ConvertFrom-Json
  } catch {
    Set-Content -Path $TxtPath -Value $Raw -Encoding UTF8
    throw "npm audit output is not valid JSON"
  }

  $Critical = 0
  if ($Audit.metadata -and $Audit.metadata.vulnerabilities -and $null -ne $Audit.metadata.vulnerabilities.critical) {
    $Critical = [int]$Audit.metadata.vulnerabilities.critical
  }

  $High = 0
  if ($Audit.metadata -and $Audit.metadata.vulnerabilities -and $null -ne $Audit.metadata.vulnerabilities.high) {
    $High = [int]$Audit.metadata.vulnerabilities.high
  }

  $Moderate = 0
  if ($Audit.metadata -and $Audit.metadata.vulnerabilities -and $null -ne $Audit.metadata.vulnerabilities.moderate) {
    $Moderate = [int]$Audit.metadata.vulnerabilities.moderate
  }

  $Low = 0
  if ($Audit.metadata -and $Audit.metadata.vulnerabilities -and $null -ne $Audit.metadata.vulnerabilities.low) {
    $Low = [int]$Audit.metadata.vulnerabilities.low
  }

  $Summary = @(
    "npm audit threshold: critical",
    "critical: $Critical",
    "high    : $High",
    "moderate: $Moderate",
    "low     : $Low",
    "exitCode: $ExitCode"
  )

  Set-Content -Path $TxtPath -Value $Summary -Encoding UTF8
  $Summary | ForEach-Object { Write-Host $_ }

  if ($Critical -gt 0) {
    throw "Critical npm vulnerabilities detected: $Critical"
  }

  if ($ExitCode -ne 0) {
    throw "npm audit failed with exit code $ExitCode"
  }

  Write-Host "[OK] npm audit critical threshold passed"
} finally {
  Pop-Location
}
