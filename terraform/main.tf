# --- Infrastructure: k3d Cluster ---
resource "shell_script" "k3d_cluster" {
  lifecycle_commands {
    create = "k3d cluster create devops-lab --agents 2 -p '8080:80@loadbalancer' --k3s-arg '--disable=traefik@server:0'"
    delete = "k3d cluster delete devops-lab"
  }
}

# --- Secret Management: Vault ---
resource "helm_release" "vault" {
  depends_on       = [shell_script.k3d_cluster]
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  namespace        = "awx-mastery"
  create_namespace = true

  set {
    name  = "server.dev.enabled"
    value = "true"
  }
}

# --- GitOps: ArgoCD ---
resource "helm_release" "argocd" {
  depends_on       = [shell_script.k3d_cluster]
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.52.0"
}

# --- AWX: Custom Credential Type ---
resource "awx_credential_type" "hashivault_dynamic_approle" {
  name        = "HashiVault Dynamic Approle"
  description = "Dynamic AppRole authentication for HashiCorp Vault"
  kind        = "cloud"

  inputs = jsonencode({
    fields = [
      { id = "vault_url",  type = "string", label = "Vault URL" },
      { id = "role_id",    type = "string", label = "Role ID" },
      { id = "secret_id",  type = "string", label = "Secret ID", secret = true }
    ]
    required = ["vault_url", "role_id", "secret_id"]
  })

  injectors = jsonencode({
    env = {
      VAULT_ADDR      = "{{ vault_url }}"
      VAULT_ROLE_ID   = "{{ role_id }}"
      VAULT_SECRET_ID = "{{ secret_id }}"
    }
  })
}

# --- AWX: Global AppRole Credential ---
resource "awx_credential" "vault_global_approle" {
  name             = "Hashi Vault Global AppRole"
  credential_type  = awx_credential_type.hashivault_dynamic_approle.id
  organization     = 1 

  inputs = jsonencode({
    vault_url = "http://vault.awx-mastery.svc.cluster.local:8200"
    role_id   = "cee77d55-b0dc-32ec-f28a-d5df6639ffd3"
    secret_id = var.vault_approle_secret_id
  })
}

# --- GitOps Application: Hello World ---
resource "kubernetes_manifest" "hello_world_app" {
  depends_on = [helm_release.argocd]
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "hello-world"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/mahder05/mahder05-lab-automation.git"
        targetRevision = "HEAD"
        path           = "guestbook"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = { prune = true, selfHeal = true }
      }
    }
  }
}

# --- Variables ---
variable "vault_approle_secret_id" {
  type      = string
  sensitive = true
}