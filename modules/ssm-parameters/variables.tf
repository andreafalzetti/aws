variable "kms_key_arn" {
  description = "KMS key used by all SecureString parameters and ciphertext decryption."
  type        = string
}

variable "generated_parameters" {
  description = "Secrets generated ephemerally; only their version marker enters state."
  type = map(object({
    name             = string
    description      = string
    length           = number
    special          = optional(bool, false)
    override_special = optional(string, "!#$%&*()-_=+[]{}:?")
    version          = number
  }))
  default = {}
}

variable "encrypted_parameters" {
  description = "External secrets committed only as KMS ciphertext."
  type = map(object({
    name        = string
    description = string
    ciphertext  = string
    version     = number
  }))
  default = {}
}
