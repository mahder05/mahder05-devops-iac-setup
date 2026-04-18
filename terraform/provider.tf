terraform {
  required_providers {
    # This maps 'shell_...' resources to the Scott Winkler provider instead of Hashicorp
    shell = {
      source  = "scottwinkler/shell"
      version = "~> 1.7.0"
    }
    # This maps 'awx_...' resources to the Denouche provider instead of Hashicorp
    awx = {
      source  = "denouche/awx"
      version = "~> 0.20.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Now define the empty provider blocks so Terraform knows they are initialized
provider "shell" {}
provider "awx" {}
provider "kubernetes" {
  # config_path = "~/.kube/config"
}