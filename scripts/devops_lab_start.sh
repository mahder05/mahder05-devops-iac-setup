#!/bin/bash

# 1. Start Colima
echo "🐳 Starting Colima..."
colima start --cpu 4 --memory 8 --disk 100 2>/dev/null || echo "✅ Colima already active."

# 2. Start k3d Cluster
echo "🌟 Starting the k3d Cluster..."
k3d cluster start devops-lab
kubectl config use-context k3d-devops-lab

# 3. Readiness Check
echo "⏳ Checking service readiness..."
echo "🛡️ Waiting for Traefik Ingress Controller..."
kubectl wait --for=condition=available deployment/traefik -n kube-system --timeout=60s

# Wait for Vault Pod
until kubectl get pod vault-0 -n awx-mastery >/dev/null 2>&1; do
    echo "   ↻ Waiting for vault-0 pod..."
    sleep 5
done

# Wait for AWX Web
echo "🚀 Waiting for AWX Web..."
kubectl wait --for=condition=Ready pod -l "app.kubernetes.io/component=web" -n awx-mastery --timeout=120s

# 4. Unseal Vault
echo "🔓 Unsealing Vault..."
kubectl exec -it vault-0 -n awx-mastery -- vault operator unseal nlMIaMxBiyoy57s0bUQ7KzxWWJnnz92UfdlbA4yu4hxI
kubectl exec -it vault-0 -n awx-mastery -- vault operator unseal xDNCPYrVDNwUwd0Oq5GkNQbMIDi16ugfLl0+mOjE18R+
kubectl exec -it vault-0 -n awx-mastery -- vault operator unseal IVxSc3YgroKpcrC01UeB84KYD6kZQVRkstQF6suFn39m

# 5. Probing Web Interfaces via Ingress (Port 8043)
echo "📡 Probing Ingress Endpoints (Port 8043)..."
urls=("http://argocd.local:8043" "http://awx.local:8043" "http://grafana.local:8043" "http://vault.local:8043")

for url in "${urls[@]}"; do
    while ! curl -s -k -f "$url" > /dev/null; do
        echo "   ↻ $url is warming up..."
        sleep 5
    done
    echo "   ✅ $url is UP!"
done

# 6. Open Browser
open "http://argocd.local:8043"
open "http://awx.local:8043"
open "http://grafana.local:8043"
open "http://vault.local:8043"

echo "✅ Lab is READY."