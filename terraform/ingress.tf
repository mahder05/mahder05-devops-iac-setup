# 1. ArgoCD Ingress (in 'argocd' namespace)
resource "kubernetes_ingress_v1" "argocd_ingress" {
  metadata {
    name      = "main-ingress"
    namespace = "argocd"
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }
  spec {
    ingress_class_name = "traefik"
    rule {
      host = "argocd.local"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# 2. AWX & Vault Ingress (in 'awx-mastery' namespace)
resource "kubernetes_ingress_v1" "devops_lab_ingress" {
  metadata {
    name      = "devops-lab-ingress"
    namespace = "awx-mastery"
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }
  spec {
    ingress_class_name = "traefik"
    rule {
      host = "awx.local"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "awx-dev-service" # Ensure this matches your AWX service name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    rule {
      host = "vault.local"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "vault"
              port {
                number = 8200
              }
            }
          }
        }
      }
    }
  }
}

# 3. Monitoring Ingress (in 'monitoring' namespace)
resource "kubernetes_ingress_v1" "monitoring_ingress" {
  metadata {
    name      = "monitoring-stack-ingress"
    namespace = "monitoring"
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }
  spec {
    ingress_class_name = "traefik"
    rule {
      host = "grafana.local"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "monitoring-grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    rule {
      host = "prometheus.local"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "prometheus-monitoring-kube-prometheus-prometheus"
              port {
                number = 9090
              }
            }
          }
        }
      }
    }
  }
}
