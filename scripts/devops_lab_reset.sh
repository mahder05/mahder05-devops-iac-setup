#!/bin/bash
CLUSTER_NAME="devops-lab"

echo "⚠️  WARNING: This will DELETE your entire cluster and rebuild it."
read -p "Are you sure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# 1. Nuke
k3d cluster delete $CLUSTER_NAME
colima stop
sleep 2

# 2. Rebuild Engine
colima start --cpu 4 --memory 8 --disk 100

# 3. Apply Infrastructure (Terraform)
cd ~/Mastery/DevOps/Infrastructure/terraform # Adjust path
terraform init
terraform apply -auto-approve

# 4. Re-run Start Script (which handles unsealing)
cd ..
./devops_lab_start.sh