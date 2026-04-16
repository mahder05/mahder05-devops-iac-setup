#!/bin/bash

# --- CONFIGURATION ---
CLUSTER_NAME="devops-lab"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}🛑 Initiating Graceful Shutdown of DevOps Lab...${NC}"

# 1. Kill Port Forwards first
# This prevents "Address already in use" errors when you restart later
echo -e "${YELLOW}🔌 Closing network tunnels...${NC}"
pkill -f "port-forward" && echo "✅ Tunnels closed." || echo "ℹ️ No active tunnels found."

# 2. Stop k3d Cluster
# This stops the containers without deleting them, preserving your lab state
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo -e "${YELLOW}🏗️  Stopping k3d cluster '$CLUSTER_NAME'...${NC}"
    k3d cluster stop "$CLUSTER_NAME"
    echo "✅ Cluster containers paused."
else
    echo "ℹ️ Cluster '$CLUSTER_NAME' is not running."
fi

# 3. Stop Colima
# This is the most important step for saving battery and RAM
if colima status >/dev/null 2>&1; then
    echo -e "${YELLOW}🐳 Shutting down Colima VM...${NC}"
    colima stop
    echo "✅ Colima engine offline."
else
    echo "ℹ️ Colima is already stopped."
fi

echo -e "\n${BLUE}===================================================${NC}"
echo -e "🏁 Lab powered down. Run ./devops_lab_start.sh to resume."
echo -e "${BLUE}===================================================${NC}"