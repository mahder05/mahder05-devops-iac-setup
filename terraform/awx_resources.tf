# 1. THE CREDENTIAL TYPE (The Template)
resource "awx_credential_type" "hashivault_approle_type" {
  name        = "HashiVault_Custom_AppRole_Type"
  description = "Custom type for Vault AppRole auth"
  kind        = "cloud"

  inputs = jsonencode({
    fields = [
      {
        id    = "address"
        label = "Vault Address"
        type  = "string"
      },
      {
        id    = "role_id"
        label = "Role ID"
        type  = "string"
      },
      {
        id     = "secret_id"
        label  = "Secret ID"
        type   = "string"
        secret = true
      }
    ]
  })

  injectors = jsonencode({
    env = {
      VAULT_ADDR      = "{{address}}"
      VAULT_ROLE_ID   = "{{role_id}}"
      VAULT_SECRET_ID = "{{secret_id}}"
    }
  })
}

# 2. THE CREDENTIAL (The Actual Instance)
resource "awx_credential" "hashivault_approle_instance" {
  name            = "HashiVault_Custom_AppRole"
  organization    = 1
  credential_type = awx_credential_type.hashivault_approle_type.id 

  inputs = jsonencode({
    address   = "http://vault.awx-mastery.svc.cluster.local:8200"
    role_id   = var.vault_role_id
    secret_id = var.vault_approle_secret_id
  })
}

# 3. Windows Machine Shell Credential
resource "awx_credential" "windows_shell" {
  name            = "Windows_Shell_Credential"
  organization    = 1
  credential_type = 1 # Standard Machine type

  inputs = jsonencode({
    # Placeholders: your vault_lookup.yml overrides these at runtime
    username = "placeholder-win"
    password = "managed-by-vault"
  })
}

# 4. Linux Machine Shell Credential (for completeness)
resource "awx_credential" "linux_shell" {
  name            = "Linux_Shell_Credential"
  organization    = 1
  credential_type = 1 

  inputs = jsonencode({
    username = "placeholder-linux"
    password = "managed-by-vault"
  })
}
# 5. THE EXECUTION ENVIRONMENT
resource "awx_execution_environment" "vault_ee" {
  name            = "Vault-Execution-Environment"
  image           = "mahder05/mahder05-vault-ee:latest"
  organization    = 1        
  pull            = "never"  # Since you are using k3d image import
}