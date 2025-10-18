$kc = "$env:USERPROFILE\.kube\config"
if (-Not (Test-Path $kc)) { throw "Kubeconfig non trouvé: $kc" }
$bytes = [IO.File]::ReadAllBytes($kc)
$b64 = [Convert]::ToBase64String($bytes)
$b64 | Set-Clipboard
Write-Host "KUBECONFIG_B64 copié dans le presse-papiers. Colle-le dans CircleCI." -ForegroundColor Green
