# --- Infrastructure: k3d Cluster ---
resource "kubernetes_namespace" "namespaces" {
  for_each = toset(["awx-mastery", "argocd", "monitoring"])
  metadata {
    name = each.key
  }
}

resource "shell_script" "k3d_cluster" {
  lifecycle_commands {
    create = "k3d cluster create devops-lab --agents 2 -p '8080:80@loadbalancer' --k3s-arg '--disable=traefik@server:0'"
    delete = "k3d cluster delete devops-lab"
  }
}

resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com" # Required to fetch from internet
  chart      = "vault"                            # The name of the chart in the repo
  namespace  = "awx-mastery"
  
  # Ensure you DO NOT have a 'chart = "./vault"' line
  # If you have a local folder named 'vault', rename it to 'vault-config' 
  # to prevent Terraform from getting confused.
}

# --- GitOps: ArgoCD ---
resource "helm_release" "argocd" {
  depends_on = [shell_script.k3d_cluster, kubernetes_namespace.namespaces]
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
}

# --- Monitoring ---
resource "helm_release" "monitoring" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  depends_on = [kubernetes_namespace.namespaces]
}

# --- GitOps Application ---
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
        repoURL        = "https://github.com/mahder05/mahder05-devops-iac-setup.git"
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
