#!/bin/bash

# --- CONFIGURATION ---
CLUSTER_NAME="devops-lab"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}⚠️  WARNING: This will destroy the cluster and all Terraform state!${NC}"
read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# 1. Kill Tunnels
echo -e "${YELLOW}🧹 Killing port-forwards...${NC}"
pkill -f "port-forward" || true

# 2. Terraform Destroy
echo -e "${YELLOW}🏗️  Running Terraform Destroy...${NC}"
terraform destroy -auto-approve -var="vault_approle_secret_id=null" || echo "Terraform destroy failed, proceeding to manual cleanup."

# 3. Manual k3d Cleanup (Safety Net)
echo -e "${YELLOW}🐳 Removing k3d cluster...${NC}"
k3d cluster delete "$CLUSTER_NAME" || true

# 4. Remove Terraform Local State
echo -e "${YELLOW}📄 Cleaning Terraform state files and locks...${NC}"
rm -rf .terraform/
rm -f .terraform.lock.hcl
rm -f terraform.tfstate*

# 5. Optional: Colima Cleanup
read -p "Do you want to delete the Colima VM too (wipes all images)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}🧨 Deleting Colima instance...${NC}"
    colima delete
fi

echo -e "${RED}===================================================${NC}"
echo -e "✨ Clean-up Complete. Environment is at Ground Zero."
echo -e "${RED}===================================================${NC}"