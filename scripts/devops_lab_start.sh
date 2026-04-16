#!/bin/bash
CLUSTER_NAME="devops-lab"
VAULT_NS="awx-mastery"

echo -e "\033[0;34m🌀 Re-hydrating DevOps Lab...\033[0m"

# 1. Start Colima
if ! colima status >/dev/null 2>&1; then
    echo -e "\033[1;33m🐳 Colima is down. Starting...\033[0m"
    colima start --cpu 4 --memory 8 --disk 100
    until docker info >/dev/null 2>&1; do printf "."; sleep 2; done
    echo -e "\n✅ Docker is ready!"
fi

# 2. Start k3d
k3d cluster start "$CLUSTER_NAME" > /dev/null 2>&1 &
echo -n "⏳ Waiting for Kubernetes API..."
until kubectl get nodes &> /dev/null; do printf "."; sleep 3; done
echo -e "\n✅ API is up!"

# 3. Vault Auto-Unseal Logic
echo -e "\033[0;34m🔐 Checking Vault Seal Status...\033[0m"
# Wait for pod to exist
until kubectl get pod vault-0 -n "$VAULT_NS" &>/dev/null; do sleep 2; done

VAULT_SEALED=$(kubectl exec -n "$VAULT_NS" vault-0 -- vault status -format=json 2>/dev/null | jq -r '.sealed')

if [ "$VAULT_SEALED" == "true" ]; then
    echo "🔓 Vault is sealed. Unsealing now..."
    kubectl exec -n "$VAULT_NS" vault-0 -- vault operator unseal kbs35vem+pRnLrrtTWIMyfsqicG++chRQbGNcUkIMkOw > /dev/null
    kubectl exec -n "$VAULT_NS" vault-0 -- vault operator unseal L62lRtwkDyHXpMII+JoTGDg3Aeoou/48HDu0nb96a7Ue > /dev/null
    kubectl exec -n "$VAULT_NS" vault-0 -- vault operator unseal s5xPNxBp0rq9ORh3Vkbn7j949JXQDDLh618fMdxyXYDC > /dev/null
    echo "✅ Vault Unsealed!"
else
    echo "✅ Vault is already unsealed."
fi

# 4. Refresh Port Forwards
echo -e "\033[0;34m🔌 Refreshing Port Forwards...\033[0m"
pkill -f "port-forward" || true
sleep 2

kubectl port-forward -n argocd svc/argocd-server 8081:443 > /dev/null 2>&1 &
kubectl port-forward -n "$VAULT_NS" svc/vault 8200:8200 > /dev/null 2>&1 &
kubectl port-forward -n "$VAULT_NS" svc/awx-dev-service 8043:80 > /dev/null 2>&1 &

echo "Waiting for services to be ready..."
sleep 5

echo "Opening in browser..."
open http://localhost:8081
open http://localhost:8043
open http://localhost:8200

echo "AWX:    http://localhost:8043"
echo "ArgoCD: http://localhost:8081"
echo "Vault:  http://localhost:8200"

echo -e "\033[0;32m🚀 Lab is fully operational!\033[0m"