🚀 **DevOps Mastery Lab**

A local, production-grade DevOps environment powered by Kubernetes (k3s) and Colima, featuring a fully integrated CI/CD and Secrets Management stack. This repository contains the Infrastructure-as-Code (IaC) and automation scripts to deploy a complete DevOps ecosystem locally. It leverages Colima for the container runtime and k3d for a lightweight Kubernetes distribution.

![Kubernetes](https://img.shields.io/badge/Kubernetes-k3s-blue?logo=kubernetes)
![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)
![Ansible](https://img.shields.io/badge/Automation-AWX-red?logo=ansible)
![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-orange?logo=argo)
![Vault](https://img.shields.io/badge/Security-Vault-black?logo=vault)
![Grafana](https://img.shields.io/badge/Observability-Grafana-F46800?logo=grafana)

🏗️ **Architecture Overview**

This lab simulates a real-world enterprise environment on a local machine:

| Component               | Tool / Technology       |
|-------------------------|--------------------------|
| Container Runtime       | Colima (macOS/Linux)     |
| Orchestration           | k3s (via k3d)            |
| Continuous Delivery     | ArgoCD                   |
| Automation/Configuration| AWX (Ansible)            |
| Secrets Management      | HashiCorp Vault          |

🏗️ **The Stack**

| Category       |Tool        | Purpose                                      |
|----------------|------------|----------------------------------------------|
| Runtime        | Colima     | Linux VM for macOS/Docker compatibility      |
| Orchestration  | k3d (k3s)  | High-performance local Kubernetes cluster    |
| IaC            | Terraform  | Automated provisioning of K8s resources      |
| GitOps         | ArgoCD     | Declarative Continuous Delivery              |
| Automation     | AWX        | Ansible-based configuration management       |
| Security       | Vault      | Centralized secrets management               |
| Observability  | Grafana    | Visualization of cluster metrics             |

🛠️ **Tech Stack & Ports**

| Service  | Access URL               | Tunnel Port   | Purpose                          |
|----------|--------------------------|--------------|----------------------------------|
| ArgoCD   | https://localhost:8081   | 443 → 8081   | GitOps & App Deployment          |
| AWX      | http://localhost:8043    | 80 → 8043    | Ansible Automation Engine        |
| Vault    | http://localhost:8200    | 8200 → 8200  | Secrets & Identity Management    |
| Grafana  | http://localhost:3000    | 80 → 3000    | Observability & Metrics          |


🚀 **Installation & Deployment Steps.**

**Prerequisites**

    Colima
    k3d
    kubectl
    Helm
    Terraform
    Homebrew

**Project Structure**

    ├── terraform/             # Infrastructure as Code
    ├── argocd/                # GitOps manifests
    ├── ansible/               # AWX playbooks
    ├── scripts/               # Start/Stop/Status automation
    ├── inventory/             # Dynamic inventory
    └── execution-environment/ # Ansible EE (Vault integration)

 **Prepare the Engine (Colima)**
      
   Colima provides the Docker/Kubernetes runtime.

    colima start --cpu 4 --memory 8 --disk 100
    
--> **Provision the Cluster (k3d & Terraform)**
   
   Create the cluster and use Terraform to deploy the core services:

    # Create the cluster
    k3d cluster create devops-lab --port "8081:443@loadbalancer"

--> **Provision Infrastructure (Terraform)**
   
   <ins>_Configuration Files Reference_</ins>

   provider.tf - Configures the Kubernetes and Helm providers to point to your k3d-devops-lab context.
   
   main.tf -  Defines the kubernetes_namespace resources and helm_release blocks for
    
    ArgoCD: argo-cd chart in argocd namespace
    Vault: vault chart in awx-mastery namespace.
    AWX Operator: awx-operator chart.
    Monitoring: kube-prometheus-stack chart.

   variables.tf & terraform.tfvars - used to manage cluster naming, toggling services on/off, and defining the list of namespaces to be created.


   Initialize and deploy the base namespaces and Helm charts (ArgoCD, Vault Operator, AWX Operator, Monitoring).

    cd terraform/
    terraform init
    terraform apply -auto-approve

--> **Deploy AWX Instance**
   
   The Terraform script installs the AWX Operator.

   Now, you must deploy the actual AWX instance using a Kubernetes Custom Resource:
   
    cat <<EOF | kubectl apply -f -
    apiVersion: awx.ansible.com/v1beta1
    kind: AWX
    metadata:
      name: awx-dev
      namespace: awx-mastery
    spec:
      service_type: clusterip
      postgres_storage_class: local-path
    EOF
    
   Wait for the pods to reach Running state:

    kubectl get pods -n awx-mastery -w. 
    
--> **Initialize & Unseal Vault**

   Since we are using a persistent Vault setup (not dev mode), you must initialize it manually the first time:Bash# Initialize Vault and save the keys!

    kubectl exec -it vault-0 -n awx-mastery -- vault operator init

    # Unseal using 3 of your generated keys
    kubectl exec -it vault-0 -n awx-mastery -- vault operator unseal <KEY_1>
    kubectl exec -it vault-0 -n awx-mastery -- vault operator unseal <KEY_2>
    kubectl exec -it vault-0 -n awx-mastery -- vault operator unseal <KEY_3>
    
--> **Configure Secrets Engine (Vault)**
  
   Once unsealed, log in and enable the Key-Value store:
   
    # Login with Root Token
    kubectl exec -it vault-0 -n awx-mastery -- vault login <ROOT_TOKEN>

--> **Enable KV2 engine**

    kubectl exec -it vault-0 -n awx-mastery -- vault secrets enable -path=secret kv-v2
    
--> **Accessing the Web UIs**

   Run the start script to establish all port-forwarding tunnels:

    ./devops_lab_start.sh
    
    Tool            Credentials
    
    ArgoCD          "User: admin | Pass: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=""{.data.password}"""
    AWX             "User: admin | Pass: `kubectl get secret awx-lab-admin-password -n awx-mastery -o jsonpath=""{.data.password}"""
    Vault           Use the Root Token generated during init
    Grafana         User: admin | Pass: prom-operator (default)


--> **Continuous Delivery (ArgoCD)**
   
   ArgoCD manages the state of the applications inside the cluster.

    Access: https://localhost:8081
    Default Login: admin
      
--> **Automation (AWX)**
   
   AWX is deployed via the AWX Operator and handles Ansible playbooks.

    Access: http://localhost:8043
    Default Login: admin

--> **Integration**

   Connected to Vault via AppRole for secure credential injection.

--> **Observability (Grafana)**

   The monitoring stack collects metrics via Prometheus.

    Access: http://localhost:3000 (via port-forward)
    Default Login: admin / admin
   
--> **Initialization**
   
   To spin up the environment, ensure Colima is running and execute the master start script:

       ./devops_lab_start.sh

--> **Vault Unsealing**
   
   Vault is configured for manual unseal to simulate production security. The devops_lab_start.sh script handles this automatically using the stored shards, flipping the Vault     pod to 1/1 Ready.

--> **Monitoring & Status**

   You can check the health of all services at any time using:
    
       ./devops_lab_status.sh

   This script validates:

       🐳 Colima engine health
       🏗️ K8s Cluster availability
       🔌 Active Port-Forwarding tunnels
       🌐 API responsiveness for Vault, ArgoCD, and AWX

--> **Cleanup**

To stop the lab and save system resources:

    ./devops_lab_stop.sh


_<ins>Security Note</ins>_

   This lab uses a Root Token for initial Vault setup and an AppRole for AWX integration. In a production environment, Root Tokens should be revoked immediately after creating      administrative policies.

💡 _Troubleshooting Tip_
   
   If terraform apply fails because the cluster isn't ready, ensure Colima is running with enough resources:

    colima start --cpu 4 --memory 8

💡 _Pro-Tips for the Lab:_ 

  Persistence: Ensure your AWX and Vault instances are backed by Persistent Volume Claims (PVCs) if you want data to survive a k3d cluster stop.
 
  Shell Aliases: Add alias k='kubectl' to your .zshrc or .bashrc for faster navigation.
  

👨‍💻 Author

**Maheshbabu Derangula**
