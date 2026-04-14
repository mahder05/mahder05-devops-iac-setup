terraform {
  required_providers {
    # We use the shell provider to manage the k3d binary execution
    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.10"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.25.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# 1. Create the Cluster via Shell (Infrastructure Layer)
resource "shell_script" "k3d_cluster" {
  lifecycle_commands {
    create = "k3d cluster create devops-lab --agents 2 -p '8080:80@loadbalancer' --k3s-arg '--disable=traefik@server:0'"
    delete = "k3d cluster delete devops-lab"
  }
}

# 2. Secret Management Layer (Vault)
resource "helm_release" "vault" {
  depends_on = [shell_script.k3d_cluster]
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = "awx-mastery"
  create_namespace = true

  set {
    name  = "server.dev.enabled"
    value = "true"
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd]
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"

  # Resource optimization for M4 Mac
  set {
    name  = "controller.resources.limits.memory"
    value = "512Mi"
  }
}