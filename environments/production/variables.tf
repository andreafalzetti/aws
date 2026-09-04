variable "aws_account_id" {
  type    = string
  default = "766515626185"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "secrets_kms_alias" {
  type    = string
  default = "alias/terraform-secrets"
}

variable "encrypted_parameters" {
  description = "External values encrypted with the dedicated KMS key."
  type = map(object({
    name        = string
    description = string
    ciphertext  = string
    version     = number
  }))
  default = {}
}
