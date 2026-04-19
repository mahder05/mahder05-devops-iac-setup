#!/bin/bash
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🌙 SHUTTING DOWN DEVOPS-LAB${NC}"

# Stop k3d
k3d cluster stop devops-lab >/dev/null 2>&1
echo -e "🏗️  k3d Cluster: ${GREEN}PAUSED${NC}"

# Stop Colima
colima stop >/dev/null 2>&1
echo -e "🐳 Colima VM: ${GREEN}OFFLINE${NC}"

echo -e "🏁 Resources Reclaimed."