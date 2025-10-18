# Suppose 'cloudflared' déjà authentifié (cloudflared tunnel login + tunnel create demo-tunnel)
# Expose l’ingress controller (80) et Grafana (3000) sous Cloudflare Tunnel configuré
Start-Process -NoNewWindow -FilePath cloudflared -ArgumentList 'tunnel run demo-tunnel'
