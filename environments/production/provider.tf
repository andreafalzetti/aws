provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
      Project     = "andreafalzetti-aws"
    }
  }
}

data "aws_caller_identity" "current" {}

check "expected_aws_account" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.aws_account_id
    error_message = "Refusing to manage an unexpected AWS account."
  }
}

data "aws_kms_alias" "secrets" {
  name = var.secrets_kms_alias
}
