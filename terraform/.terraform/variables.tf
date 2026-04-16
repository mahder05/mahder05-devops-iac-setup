variable "awx_password" {
  description = "The admin password for AWX"
  type        = string
  sensitive   = true
}

variable "vault_root_token" {
  description = "The initial root token for Vault"
  type        = string
  sensitive   = true
}