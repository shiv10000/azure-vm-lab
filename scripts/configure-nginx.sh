#!/usr/bin/env bash
set -euo pipefail

PUBLIC_IP="${1:-}"
SSH_KEY_PATH="${HOME}/.ssh/azure-vm-lab"
ADMIN_USER="azureuser"

if [[ -z "${PUBLIC_IP}" ]]; then
  echo "Usage: $0 PUBLIC_IP"
  exit 1
fi

ssh -i "${SSH_KEY_PATH}" "${ADMIN_USER}@${PUBLIC_IP}" <<'REMOTE'
set -euo pipefail
sudo apt-get update
sudo apt-get install -y nginx
sudo systemctl enable --now nginx

cat <<'HTML' | sudo tee /var/www/html/index.html >/dev/null
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Azure VM Lab</title>
  </head>
  <body>
    <h1>Azure VM Administration Lab</h1>
    <p>Nginx is running successfully on Ubuntu.</p>
  </body>
</html>
HTML

sudo nginx -t
curl -I http://localhost
REMOTE

echo "Open http://${PUBLIC_IP} in a browser."

