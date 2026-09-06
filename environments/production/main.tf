locals {
  generated_parameters = merge(
    local.crm_demo_generated_parameters,
    local.gioco_generated_parameters,
    local.n8n_demo_generated_parameters,
  )
}

module "ssm_parameters" {
  source = "../../modules/ssm-parameters"

  kms_key_arn          = data.aws_kms_alias.secrets.target_key_arn
  generated_parameters = local.generated_parameters
  encrypted_parameters = var.encrypted_parameters
}
