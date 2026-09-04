resource "aws_kms_key" "terraform_state" {
  description             = "Encrypts Terraform state for andreafalzetti/aws"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Purpose = "terraform-state"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}

resource "aws_kms_key" "terraform_secrets" {
  description             = "Encrypts GitOps ciphertext and SSM SecureString parameters"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Purpose = "application-secrets"
  }
}

resource "aws_kms_alias" "terraform_secrets" {
  name          = "alias/terraform-secrets"
  target_key_id = aws_kms_key.terraform_secrets.key_id
}
