#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}📊 DEVOPS-LAB COMPREHENSIVE STATUS${NC}"
echo -e "${BLUE}================================================${NC}"

# 1. Colima / Docker VM
echo -ne "🐳 Colima VM: "
colima status >/dev/null 2>&1 && echo -e "${GREEN}RUNNING${NC}" || echo -e "${RED}STOPPED${NC}"

# 2. k3d Cluster
echo -ne "☸️  k3d Cluster: "
k3d cluster list | grep -q "devops-lab.*1/1" && echo -e "${GREEN}ACTIVE${NC}" || echo -e "${RED}INACTIVE${NC}"

# 3. Vault Seal Status
echo -ne "🔐 Vault Status: "
SEAL_CHECK=$(kubectl exec -it vault-0 -n awx-mastery -- vault status 2>/dev/null | grep "Sealed" | awk '{print $2}')
if [ "$SEAL_CHECK" == "false" ]; then
    echo -e "${GREEN}UNSEALED${NC}"
else
    echo -e "${RED}SEALED/OFFLINE${NC}"
fi

# 4. Ingress Health
echo -e "\n🌐 [INGRESS ROUTES]"
ingresses=("argocd/main-ingress" "awx-mastery/devops-lab-ingress" "monitoring/monitoring-stack-ingress")
for ing in "${ingresses[@]}"; do
    NS=$(echo $ing | cut -d'/' -f1)
    NAME=$(echo $ing | cut -d'/' -f2)
    ADDR=$(kubectl get ingress $NAME -n $NS -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    [ -n "$ADDR" ] && echo -e "   [${GREEN}OK${NC}] $NAME -> $ADDR" || echo -e "   [${RED}!!${NC}] $NAME -> Pending"
done

echo -e "${BLUE}================================================${NC}"