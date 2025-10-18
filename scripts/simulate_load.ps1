param(
  [string]$Url = "https://demo.ton-domaine.dev/search?query=test",
  [int]$Rps = 150,
  [int]$Seconds = 90
)
Write-Host "Load test $Url RPS=$Rps for $Seconds s"
# Requiert 'bombardier' (winget install Go.Bombardier ou choco install bombardier)
bombardier -c 50 -d ${Seconds}s -l -r $Rps $Url
