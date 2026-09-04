ephemeral "random_password" "generated" {
  for_each = var.generated_parameters

  length           = each.value.length
  special          = each.value.special
  override_special = each.value.special ? each.value.override_special : null
}

resource "aws_ssm_parameter" "generated" {
  for_each = var.generated_parameters

  name        = each.value.name
  description = each.value.description
  type        = "SecureString"
  tier        = "Standard"
  key_id      = var.kms_key_arn

  value_wo         = ephemeral.random_password.generated[each.key].result
  value_wo_version = each.value.version

  tags = {
    SecretKind = "generated"
  }
}

ephemeral "aws_kms_secrets" "encrypted" {
  for_each = var.encrypted_parameters

  secret {
    name    = each.key
    payload = each.value.ciphertext
    key_id  = var.kms_key_arn

    context = {
      ssm_parameter_name = each.value.name
    }
  }
}

resource "aws_ssm_parameter" "encrypted" {
  for_each = var.encrypted_parameters

  name        = each.value.name
  description = each.value.description
  type        = "SecureString"
  tier        = "Standard"
  key_id      = var.kms_key_arn

  value_wo         = ephemeral.aws_kms_secrets.encrypted[each.key].plaintext[each.key]
  value_wo_version = each.value.version

  tags = {
    SecretKind = "external-ciphertext"
  }
}
