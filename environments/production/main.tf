locals {
  generated_parameters = {
    n8n_encryption_key = {
      name        = "/crm-demo/production/n8n/encryption-key"
      description = "Stable n8n credential encryption key"
      length      = 64
      special     = false
      version     = 1
    }
    postgres_password = {
      name        = "/crm-demo/production/postgres/password"
      description = "PostgreSQL application password for n8n"
      length      = 48
      special     = false
      version     = 1
    }
    pocketbase_encryption_key = {
      name        = "/crm-demo/production/demo/pocketbase/encryption-key"
      description = "32-character PocketBase settings encryption key"
      length      = 32
      special     = false
      version     = 1
    }
  }
}

module "ssm_parameters" {
  source = "../../modules/ssm-parameters"

  kms_key_arn          = data.aws_kms_alias.secrets.target_key_arn
  generated_parameters = local.generated_parameters
  encrypted_parameters = var.encrypted_parameters
}
