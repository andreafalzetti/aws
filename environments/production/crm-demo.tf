locals {
  crm_demo_generated_parameters = {
    pocketbase_encryption_key = {
      name        = "/crm-demo/production/demo/pocketbase/encryption-key"
      description = "32-character PocketBase settings encryption key"
      length      = 32
      special     = false
      version     = 1
      tags = {
        Workload = "crm-demo"
      }
    }
  }
}
