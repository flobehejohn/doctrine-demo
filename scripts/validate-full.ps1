[CmdletBinding()]
param(
  [string]$RepoRoot = "",
  [string]$OutDir = "audit",
  [string]$RunStamp = "",
  [switch]$SkipDocker,
  [switch]$DockerOptional,
  [switch]$Archive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = (Get-Location).Path
}

if ([string]::IsNullOrWhiteSpace($RunStamp)) {
  $RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
}

$OutDirAbs = Join-Path $RepoRoot $OutDir
$RunDir = if ($Archive) {
  Join-Path $OutDirAbs ("VALID_" + $RunStamp)
} else {
  Join-Path $OutDirAbs "_latest"
}

New-Item -ItemType Directory -Force -Path $RunDir | Out-Null

$Steps = New-Object System.Collections.Generic.List[object]

function Write-StepLog {
  param(
    [string]$Path,
    [object[]]$Lines
  )

  $Dir = Split-Path -Parent $Path
  if ($Dir -and -not (Test-Path $Dir)) {
    New-Item -ItemType Directory -Force -Path $Dir | Out-Null
  }

  $SafeLines = @()
  if ($null -ne $Lines) {
    $SafeLines = @($Lines) | Where-Object { $null -ne $_ }
  }
  $Text = ($SafeLines | ForEach-Object { $_.ToString() }) -join "`r`n"
  Set-Content -Path $Path -Value $Text -Encoding UTF8
}

function Invoke-GateStep {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][scriptblock]$Command
  )

  $StepDir = Join-Path $RunDir $Name
  New-Item -ItemType Directory -Force -Path $StepDir | Out-Null
  $LogPath = Join-Path $StepDir "$Name.log"

  $Sw = [System.Diagnostics.Stopwatch]::StartNew()
  $Status = "OK"
  $ExitCode = 0
  $Output = @()

  Write-Host ""
  Write-Host "=== $Name ===" -ForegroundColor Cyan

  try {
    $global:LASTEXITCODE = 0
    $Output = @(@(& $Command 2>&1) | Where-Object { $null -ne $_ })
    $ExitCode = if ($null -ne $global:LASTEXITCODE) { [int]$global:LASTEXITCODE } else { 0 }

    if ($Output) {
      $Output | ForEach-Object { Write-Host $_ }
    }

    if ($ExitCode -ne 0) {
      throw "$Name failed with exit code $ExitCode"
    }
  } catch {
    $Status = "ERR"
    if ($ExitCode -eq 0) {
      $ExitCode = 1
    }

    $Output = @($Output) + @($_.Exception.Message)
    Write-Host "[ERR] $($_.Exception.Message)" -ForegroundColor Red
  } finally {
    $Sw.Stop()
    Write-StepLog -Path $LogPath -Lines $Output

    $Steps.Add([pscustomobject]@{
      name = $Name
      status = $Status
      exitCode = $ExitCode
      durationMs = $Sw.ElapsedMilliseconds
      log = $LogPath
    }) | Out-Null
  }
}

function Assert-FileExists {
  param([string]$RelativePath)

  $FullPath = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path $FullPath)) {
    throw "Missing required file: $RelativePath"
  }
}

function Test-DockerAvailable {
  try {
    $Version = docker version --format "{{.Server.Version}}" 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($Version)) {
      return $true
    }
  } catch {
    return $false
  }

  return $false
}
Push-Location $RepoRoot

try {
  Invoke-GateStep -Name "source-hygiene" -Command {
    git diff --check
  }

  Invoke-GateStep -Name "docs-contract" -Command {
    $RequiredFiles = @(
      "README.md",
      "CHECKLIST.md",
      "RUNBOOK.md",
      "SLO.md",
      "METRICS.md",
      "ROUTES.md",
      "docs/case-studies/observability-ci.md",
      "docs/proofs/README.md",
      "docs/proofs/observability-evidence.md",
      "docs/proofs/observability-evidence.json",
      "docs/adr/ADR-0001-staff-ci-observability-proof-pack.md",
      "docs/operations/docker-deferred-validation.md"
    )

    foreach ($File in $RequiredFiles) {
      Assert-FileExists $File
      Write-Host "[OK] $File"
    }

    $Package = Get-Content -Raw -Path "app/package.json"
    if ($Package -match "no tests yet") {
      throw "app/package.json still contains a fake test script."
    }

    $Circle = Get-Content -Raw -Path ".circleci/config.yml"
    if ($Circle -match "\|\|\s*echo") {
      throw "CircleCI still tolerates failing tests via '|| echo'."
    }

    Write-Host "[OK] documentation and CI contracts are strict"
  }

  Invoke-GateStep -Name "npm-ci" -Command {
    npm ci --prefix app
  }

  Invoke-GateStep -Name "node-contract-tests" -Command {
    npm test --prefix app
  }

  if (-not $SkipDocker -and -not (Test-DockerAvailable)) {
    $Message = "Docker engine unavailable. Start Docker Desktop Linux Engine, or run with -SkipDocker. Local non-Docker gates remain valid."
    if ($DockerOptional) {
      Write-Host "[WARN] $Message" -ForegroundColor Yellow
      $Steps.Add([pscustomobject]@{
        name = "docker-prerequisite"
        status = "WARN"
        exitCode = 0
        durationMs = 0
        log = Join-Path $RunDir "docker-prerequisite/docker-prerequisite.log"
      }) | Out-Null
      $PrereqLog = Join-Path $RunDir "docker-prerequisite/docker-prerequisite.log"
      Write-StepLog -Path $PrereqLog -Lines @($Message)
      $SkipDocker = $true
    } else {
      throw $Message
    }
  }

  if (-not $SkipDocker) {
    $ImageName = "doctrine-demo:ci-$RunStamp"
    $ContainerName = "doctrine-demo-ci-$RunStamp"
    $Port = Get-Random -Minimum 19080 -Maximum 19999

    Invoke-GateStep -Name "docker-build" -Command {
      docker build -f app/Dockerfile -t $ImageName app
    }

    Invoke-GateStep -Name "container-smoke" -Command {
      docker rm -f $ContainerName 2>$null | Out-Null

      $ContainerId = docker run -d --name $ContainerName -p "127.0.0.1:${Port}:8080" `
        -e NODE_ENV=production `
        -e LATENCY_MS=0 `
        -e RATE_LIMIT_MAX=1000 `
        -e CORS_ORIGINS="*" `
        $ImageName

      if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($ContainerId)) {
        throw "docker run failed"
      }

      try {
        $BaseUrl = "http://127.0.0.1:$Port"
        $Healthy = $false

        for ($i = 0; $i -lt 30; $i++) {
          try {
            $Health = Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri "$BaseUrl/healthz"
            if ($Health.StatusCode -eq 200 -and $Health.Content.Trim() -eq "ok") {
              $Healthy = $true
              break
            }
          } catch {
            Start-Sleep -Seconds 1
          }
        }

        if (-not $Healthy) {
          docker logs $ContainerName
          throw "container health check did not become ready"
        }

        $Search = Invoke-RestMethod -TimeoutSec 5 -Uri "$BaseUrl/search?query=ci"
        if ($Search.query -ne "ci") {
          throw "unexpected /search response"
        }

        $Metrics = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 -Uri "$BaseUrl/metrics").Content
        if ($Metrics -notmatch "http_requests_total") {
          throw "missing http_requests_total in /metrics"
        }

        if ($Metrics -notmatch "http_request_duration_seconds") {
          throw "missing http_request_duration_seconds in /metrics"
        }

        Write-Host "[OK] container smoke passed on $BaseUrl"
      } finally {
        docker rm -f $ContainerName 2>$null | Out-Null
      }
    }
  }

  $Overall = if ($Steps | Where-Object { $_.status -eq "ERR" }) { "ERR" } else { "OK" }

  $Summary = [pscustomobject]@{
    timestamp = (Get-Date).ToString("o")
    runStamp = $RunStamp
    repoRoot = $RepoRoot
    runDir = $RunDir
    overall = $Overall
    steps = $Steps
  }

  $Summary | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $RunDir "summary.json") -Encoding UTF8

  $Text = New-Object System.Collections.Generic.List[string]
  $Text.Add("runStamp: $RunStamp") | Out-Null
  $Text.Add("repoRoot : $RepoRoot") | Out-Null
  $Text.Add("runDir   : $RunDir") | Out-Null
  $Text.Add("overall  : $Overall") | Out-Null

  foreach ($Step in $Steps) {
    $Seconds = [Math]::Round($Step.durationMs / 1000, 2)
    $Text.Add(("{0} {1} {2}s exit={3} log={4}" -f $Step.status, $Step.name, $Seconds, $Step.exitCode, $Step.log)) | Out-Null
  }

  Set-Content -Path (Join-Path $RunDir "summary.txt") -Value ($Text -join "`r`n") -Encoding UTF8

  Write-Host ""
  Write-Host "=== Summary ===" -ForegroundColor Yellow
  Get-Content -Path (Join-Path $RunDir "summary.txt")

  if ($Overall -ne "OK") {
    exit 1
  }

  exit 0
} finally {
  Pop-Location
}


