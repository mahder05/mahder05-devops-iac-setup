🚀 DevOps Mastery Lab

A local, production-grade DevOps environment powered by Kubernetes (k3s) and Colima, featuring a fully integrated CI/CD and Secrets Management stack.

🏗️ Architecture Overview

This lab simulates a real-world enterprise environment on a local machine:

    Container Runtime: Colima (macOS/Linux)
    Orchestration: k3s (via k3d)
    Continuous Delivery: ArgoCD
    Automation/Configuration: AWX (Ansible)
    Secrets Management: HashiCorp Vault

🛠️ Tech Stack & Ports

    Service          Access URL              Tunnel Port     Purpose**
    ArgoCD           https://localhost:8081  443 -> 8081     GitOps & App Deployment
    AWX              http://localhost:8043   80 -> 8043      Ansible Automation Engine
    Vault            http://localhost:8200   8200 -> 8200    Secrets & Identity Management
    Grafana          http://localhost:3000   80 -> 3000      Observability & Metrics

🚀 Getting Started

1. Prerequisites

       Colima
       k3d
       kubectl
       Helm

2. Initialization
   To spin up the environment, ensure Colima is running and execute the master start script:

       ./devops_lab_start.sh

3. Vault Unsealing
   
   Vault is configured for manual unseal to simulate production security. The devops_lab_start.sh script handles this automatically using the stored shards, flipping the Vault      pod to 1/1 Ready.

4. Project Structure
   
       /terraform - Infrastructure as Code for cluster resources.
       /argocd - Application manifests and sync policies.
       /ansible - AWX Playbooks and job templates.
       /scripts - Automation for lab lifecycle (Start/Stop/Status).

5. Monitoring & Status

   You can check the health of all services at any time using:
    
       ./devops_lab_status.sh

   This script validates:

       🐳 Colima engine health
       🏗️ K8s Cluster availability
       🔌 Active Port-Forwarding tunnels
       🌐 API responsiveness for Vault, ArgoCD, and AWX

6. Security NoteThis lab uses a Root Token for initial Vault setup and an AppRole for AWX integration. In a production environment, Root Tokens should be revoked immediately after creating administrative policies.

💡 Pro-Tips for the Lab:Persistence: Ensure your AWX and Vault instances are backed by Persistent Volume Claims (PVCs) if you want data to survive a k3d cluster stop.Shell Aliases: Add alias k='kubectl' to your .zshrc or .bashrc for faster navigation.

👨‍💻 Author

Maheshbabu Derangula
