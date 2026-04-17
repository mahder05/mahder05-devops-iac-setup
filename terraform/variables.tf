variable "vault_role_id" {
  description = "The Role ID for the Vault AppRole"
  type        = string
}

variable "vault_approle_secret_id" {
  description = "The Secret ID for the Vault AppRole"
  type        = string
  sensitive   = true
}

variable "awx_password" {
  description = "Admin password for AWX"
  type        = string
  sensitive   = true
}

variable "vault_root_token" {
  description = "The root token for Vault (used for manual bootstrapping)"
  type        = string
  sensitive   = true
}