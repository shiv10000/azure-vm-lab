#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP="azure-vm-monitoring-lab-rg"

echo "This permanently deletes every resource in: ${RESOURCE_GROUP}"
read -r -p "Type DELETE to continue: " CONFIRM
[[ "${CONFIRM}" == "DELETE" ]] || {
  echo "Cancelled."
  exit 0
}

az group delete \
  --name "${RESOURCE_GROUP}" \
  --yes

echo "Deletion request completed. Resource group exists:"
az group exists --name "${RESOURCE_GROUP}"

