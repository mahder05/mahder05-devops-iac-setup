#!/bin/bash

# --- CONFIGURATION ---
CLUSTER_NAME="devops-lab"
VAULT_ADDR="http://localhost:8200"
ARGOCD_ADDR="https://localhost:8081"
AWX_ADDR="http://localhost:8043"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔍 Checking DevOps Lab Health Status...${NC}\n"

# 1. Colima Engine Status
echo -n "🐳 Colima Engine: "
if colima status >/dev/null 2>&1; then
    echo -e "${GREEN}RUNNING${NC}"
else
    echo -e "${RED}STOPPED${NC}"
fi

# 2. k3d Cluster Status
echo -n "🏗️  k3s Cluster:  "
K3D_STATUS=$(k3d cluster list "$CLUSTER_NAME" --no-headers 2>/dev/null | awk '{print $3}')
if [[ "$K3D_STATUS" == *"1/1"* ]] || [[ "$K3D_STATUS" == *"running"* ]]; then
    echo -e "${GREEN}ACTIVE${NC}"
else
    echo -e "${RED}OFFLINE ($K3D_STATUS)${NC}"
fi

# 3. Port Forwarding Check
echo -n "🔌 Port Tunnels: "
PF_COUNT=$(pgrep -f "port-forward" | wc -l | xargs)
if [ "$PF_COUNT" -gt 0 ]; then
    echo -e "${GREEN}ACTIVE ($PF_COUNT tunnels)${NC}"
else
    echo -e "${YELLOW}INACTIVE (Run ./devops_lab_start.sh)${NC}"
fi

echo -e "\n${BLUE}🌐 Service API Health:${NC}"
echo "---------------------------------------------------"

# Vault Check (Standard HTTP)
if curl -s -o /dev/null --connect-timeout 2 "$VAULT_ADDR/v1/sys/health"; then
    echo -e "🔐 Vault API   | ${GREEN}OK (Accessible)${NC}"
else
    echo -e "🔐 Vault API   | ${RED}UNREACHABLE${NC}"
fi

# ArgoCD Check (HTTPS/Self-signed)
if curl -s -k -o /dev/null --connect-timeout 2 "$ARGOCD_ADDR"; then
    echo -e "🐙 ArgoCD API  | ${GREEN}OK (Accessible)${NC}"
else
    echo -e "🐙 ArgoCD API  | ${RED}UNREACHABLE${NC}"
fi

# AWX Check (HTTP based on your working curl)
if curl -s -o /dev/null --connect-timeout 2 "$AWX_ADDR/"; then
    echo -e "🤖 AWX API     | ${GREEN}OK (Accessible)${NC}"
else
    echo -e "🤖 AWX API     | ${RED}UNREACHABLE${NC}"
fi

echo -e "---------------------------------------------------"

# 4. Resource Usage
echo -e "\n${BLUE}📈 Resource Consumption (Colima):${NC}"
colima list -j 2>/dev/null | jq -r 'select(.status=="running") | "CPU: \(.cpus) | RAM: \(.memory)Gi | Disk: \(.disk)Gi"' || echo "No active Colima instance."

echo -e "\n${YELLOW}💡 Tip: If APIs are unreachable but Cluster is active, rerun ./devops_lab_start.sh${NC}"