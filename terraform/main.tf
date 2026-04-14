# ==========================================
# 1. TERRAFORM & PROVIDER CONFIGURATION
# ==========================================
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
    awx = {
      source  = "jylitalo/awx"
      version = "0.22.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "vault" {
  address = "http://127.0.0.1:8200"
  # Token is passed via environment variable: export VAULT_TOKEN="..."
}

provider "awx" {
  endpoint = "http://localhost:8080" # Update with Minikube IP if needed
  username = "admin"
  password = var.awx_password
}

# ==========================================
# 2. VARIABLES (Passed via CLI to stay safe)
# ==========================================
variable "awx_password" {
  type      = string
  sensitive = true
}

variable "vault_role_id" {
  type      = string
  sensitive = true
}

variable "vault_secret_id" {
  type      = string
  sensitive = true
}

# ==========================================
# 3. KUBERNETES RESOURCES
# ==========================================
resource "kubernetes_namespace" "lab_space" {
  metadata {
    name = "production-ready-lab"
  }
}

# Example Pod (Nginx) inside your namespace
resource "kubernetes_pod" "nginx_test" {
  metadata {
    name      = "nginx-test"
    namespace = kubernetes_namespace.lab_space.metadata[0].name
  }

  spec {
    container {
      image = "nginx:latest"
      name  = "nginx-container"
      port {
        container_port = 80
      }
    }
  }
}

# ==========================================
# 4. AWX & VAULT INTEGRATION (The Bridge)
# ==========================================

# This creates the AppRole credential inside the AWX UI
resource "awx_credential" "vault_approle" {
  name            = "Vault AppRole Credential"
  organization_id = 1
  credential_type = "Hashicorp_Vault_AppRole"

  inputs = jsonencode({
    address   = "http://vault.vault.svc.cluster.local:8200" # Internal K8s address
    role_id   = var.vault_role_id
    secret_id = var.vault_secret_id
  })
}