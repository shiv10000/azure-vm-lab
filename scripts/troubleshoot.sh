#!/usr/bin/env bash
set -u

PUBLIC_IP="${1:-}"
RESOURCE_GROUP="azure-vm-monitoring-lab-rg"
VM_NAME="azure-vm-lab"
NSG_NAME="azure-vm-lab-nsg"
SSH_KEY_PATH="${HOME}/.ssh/azure-vm-lab"

if [[ -z "${PUBLIC_IP}" ]]; then
  echo "Usage: $0 PUBLIC_IP"
  exit 1
fi

echo "1. Azure VM power state"
az vm get-instance-view \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${VM_NAME}" \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" \
  --output tsv

echo "2. Public IP supplied: ${PUBLIC_IP}"

echo "3. Effective lab NSG rules"
az network nsg rule list \
  --resource-group "${RESOURCE_GROUP}" \
  --nsg-name "${NSG_NAME}" \
  --query "[].{Name:name,Priority:priority,Source:sourceAddressPrefix,Port:destinationPortRange,Access:access}" \
  --output table

echo "4. HTTP test from this computer"
curl --connect-timeout 5 -I "http://${PUBLIC_IP}" || true

echo "5. Nginx, listening ports, local HTTP, and UFW on the VM"
ssh -o ConnectTimeout=5 -i "${SSH_KEY_PATH}" "azureuser@${PUBLIC_IP}" \
  'sudo systemctl --no-pager status nginx; sudo ss -lntp; curl -I http://localhost; sudo ufw status verbose' || true

