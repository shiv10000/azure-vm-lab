#!/usr/bin/env bash
set -euo pipefail

# Azure resource names are kept together so the lab is easy to inspect.
RESOURCE_GROUP="azure-vm-monitoring-lab-rg"
LOCATION="southeastasia"
VM_NAME="azure-vm-lab"
ADMIN_USER="azureuser"
VNET_NAME="azure-vm-lab-vnet"
SUBNET_NAME="default"
NSG_NAME="azure-vm-lab-nsg"
PUBLIC_IP_NAME="azure-vm-lab-public-ip"
NIC_NAME="azure-vm-lab-nic"
SSH_KEY_PATH="${HOME}/.ssh/azure-vm-lab"

command -v az >/dev/null || {
  echo "Azure CLI is required: https://learn.microsoft.com/cli/azure/install-azure-cli"
  exit 1
}

az account show >/dev/null 2>&1 || {
  echo "Sign in first with: az login"
  exit 1
}

# Discover the caller's public IPv4 address. Port 22 will accept only this /32.
MY_IP="$(curl -4fsS https://api.ipify.org)"
[[ "${MY_IP}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Could not determine a valid public IPv4 address."
  exit 1
}

if [[ ! -f "${SSH_KEY_PATH}" ]]; then
  ssh-keygen -t ed25519 -f "${SSH_KEY_PATH}" -C "azure-vm-lab" -N ""
fi

echo "Active Azure subscription:"
az account show --query '{name:name,user:user.name}' --output table
echo
read -r -p "Create billable lab resources in this subscription? Type YES: " CONFIRM
[[ "${CONFIRM}" == "YES" ]] || {
  echo "Cancelled."
  exit 0
}

az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --output table

az network vnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --name "${VNET_NAME}" \
  --address-prefixes "10.10.0.0/16" \
  --subnet-name "${SUBNET_NAME}" \
  --subnet-prefixes "10.10.1.0/24" \
  --output table

az network nsg create \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --name "${NSG_NAME}" \
  --output table

az network nsg rule create \
  --resource-group "${RESOURCE_GROUP}" \
  --nsg-name "${NSG_NAME}" \
  --name "Allow-SSH-From-My-IP" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "${MY_IP}/32" \
  --destination-port-ranges 22 \
  --output table

az network nsg rule create \
  --resource-group "${RESOURCE_GROUP}" \
  --nsg-name "${NSG_NAME}" \
  --name "Allow-HTTP" \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes Internet \
  --destination-port-ranges 80 \
  --output table

az network public-ip create \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --name "${PUBLIC_IP_NAME}" \
  --sku Standard \
  --allocation-method Static \
  --output table

az network nic create \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --name "${NIC_NAME}" \
  --vnet-name "${VNET_NAME}" \
  --subnet "${SUBNET_NAME}" \
  --network-security-group "${NSG_NAME}" \
  --public-ip-address "${PUBLIC_IP_NAME}" \
  --output table

# Student subscriptions vary by region and quota. Select the first available
# candidate, then explicitly display it before VM creation.
CANDIDATE_SIZES=("Standard_B1s" "Standard_B1ls" "Standard_B2ats_v2")
VM_SIZE=""
AVAILABLE_SIZES="$(az vm list-sizes --location "${LOCATION}" --query '[].name' -o tsv)"
for SIZE in "${CANDIDATE_SIZES[@]}"; do
  if grep -qx "${SIZE}" <<<"${AVAILABLE_SIZES}"; then
    VM_SIZE="${SIZE}"
    break
  fi
done

[[ -n "${VM_SIZE}" ]] || {
  echo "None of the small candidate VM sizes are listed in ${LOCATION}."
  echo "Check allowed sizes with: az vm list-sizes -l ${LOCATION} -o table"
  exit 1
}
echo "Selected VM size: ${VM_SIZE}"

az vm create \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --name "${VM_NAME}" \
  --nics "${NIC_NAME}" \
  --image Ubuntu2204 \
  --size "${VM_SIZE}" \
  --admin-username "${ADMIN_USER}" \
  --ssh-key-values "${SSH_KEY_PATH}.pub" \
  --authentication-type ssh \
  --output table

# 1900 means 19:00 UTC. Change this to suit the desired UTC shutdown time.
az vm auto-shutdown \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${VM_NAME}" \
  --time "1900"

PUBLIC_IP="$(az network public-ip show \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${PUBLIC_IP_NAME}" \
  --query ipAddress \
  --output tsv)"

echo
echo "VM created."
echo "Public IP: ${PUBLIC_IP}"
echo "SSH: ssh -i ${SSH_KEY_PATH} ${ADMIN_USER}@${PUBLIC_IP}"

