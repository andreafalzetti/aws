locals {
  crm_demo_generated_parameters = {
    assistant_shared_secret = {
      name        = "/crm-demo/production/demo/assistant/shared-secret"
      description = "Shared HMAC secret for CRM assistant delegation and n8n webhook authentication"
      length      = 64
      special     = false
      version     = 1
      tags = {
        Workload = "crm-demo"
      }
    }
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
