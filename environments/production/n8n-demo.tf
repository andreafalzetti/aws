locals {
  n8n_demo_generated_parameters = {
    n8n_encryption_key = {
      name        = "/n8n-demo/production/encryption-key"
      description = "Stable credential encryption key for the independent n8n demo instance"
      length      = 64
      special     = false
      version     = 1
      tags = {
        Workload = "n8n-demo"
      }
    }
    postgres_password = {
      name        = "/n8n-demo/production/postgres/password"
      description = "PostgreSQL application password for the independent n8n demo instance"
      length      = 48
      special     = false
      version     = 1
      tags = {
        Workload = "n8n-demo"
      }
    }
  }
}
