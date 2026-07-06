# Azure VM Administration and Monitoring Lab

Hands-on lab for deploying an Ubuntu virtual machine with Azure CLI, securing
network access, serving a website with Nginx, monitoring the VM, diagnosing
common failures, and removing all lab resources afterward.

> **Cost warning:** A running VM and its related resources consume Azure credit.
> Complete this as a short lab and run the cleanup script when finished.

## Architecture

```text
Browser
   │ HTTP :80 (public)
   ▼
Public IP → Network Security Group → Ubuntu VM → Nginx
                                             ▲
                                             │ SSH :22 (your public IP only)
                                             └──────────────────────────────
```

## What this lab teaches

- Resource groups and Azure CLI
- SSH public/private key authentication
- Virtual networks, subnets, public IPs, and private IPs
- Network Security Group rules for SSH and HTTP
- Ubuntu package and service administration
- Nginx installation and verification
- Azure Monitor metrics
- Troubleshooting VM, network, service, and firewall failures
- Cost control through automatic shutdown and resource cleanup

## Repository structure

```text
.
├── README.md
├── scripts
│   ├── create-vm.sh
│   ├── configure-nginx.sh
│   ├── troubleshoot.sh
│   └── cleanup.sh
└── screenshots
    └── README.md
```

## Lab configuration

The scripts use:

- Region: `southeastasia`
- Resource group: `azure-vm-monitoring-lab-rg`
- VM name: `azure-vm-lab`
- Ubuntu image: `Ubuntu2204`
- SSH: port 22, restricted to your current public IPv4 address
- HTTP: port 80, open publicly

The creation script asks Azure to choose the first available VM size from a
small list. Review the selected size and its price in the Azure portal before
continuing.

## Prerequisites

Install Azure CLI, then sign in:

```bash
az login
az account show --output table
```

Confirm that the active subscription is the intended student subscription
before creating anything.

## Stage 1: Create the VM

Run:

```bash
chmod +x scripts/*.sh
./scripts/create-vm.sh
```

The script creates an SSH key locally if it does not exist, then creates the
resource group, networking, NSG rules, public IP, and VM. Read the script before
running it—the commands are intentionally separated and commented for learning.

Connect using the public IP printed by the script:

```bash
ssh -i ~/.ssh/azure-vm-lab azureuser@PUBLIC_IP
```

## Stage 2: Install Nginx

From this repository, pass the VM public IP to:

```bash
./scripts/configure-nginx.sh PUBLIC_IP
```

Then open:

```text
http://PUBLIC_IP
```

## Stage 3: Monitor

In the Azure portal, open the VM and select **Monitoring → Metrics**. Observe:

- Percentage CPU
- Network In Total
- Network Out Total
- VM availability

Generate a little HTTP traffic by refreshing the Nginx page and note the network
metric change. Add sanitized screenshots to `screenshots/`.

## Stage 4: Troubleshoot

Use:

```bash
./scripts/troubleshoot.sh PUBLIC_IP
```

Diagnose each layer in order:

1. Is the VM running?
2. Is the public IP correct?
3. Does the NSG allow the port?
4. Is Nginx active and listening on port 80?
5. Is Ubuntu's UFW firewall blocking traffic?

Useful remote checks:

```bash
sudo systemctl status nginx
sudo ss -lntp
sudo ufw status verbose
curl -I http://localhost
```

## Stage 5: Clean up

Delete the entire isolated resource group:

```bash
./scripts/cleanup.sh
```

Verify that deletion completed:

```bash
az group exists --name azure-vm-monitoring-lab-rg
```

The expected result is `false`.

## Screenshot safety

Do not include subscription IDs, tenant IDs, email addresses, tokens, passwords,
private SSH keys, or other secrets. Crop or redact identifiers that do not add
learning value.

## Completion checklist

- [ ] Resource group created in `southeastasia`
- [ ] SSH key authentication verified
- [ ] Port 22 restricted to the learner's public IP
- [ ] Port 80 publicly accessible
- [ ] Nginx page visible in a browser
- [ ] Azure Monitor metrics reviewed
- [ ] Failure scenarios diagnosed
- [ ] Sanitized evidence added
- [ ] Resource group deleted and deletion verified

