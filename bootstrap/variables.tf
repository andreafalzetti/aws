variable "aws_account_id" {
  description = "AWS account that this repository is allowed to manage."
  type        = string
  default     = "766515626185"
}

variable "aws_region" {
  description = "Primary AWS region."
  type        = string
  default     = "eu-central-1"
}

variable "state_bucket_name" {
  description = "Globally unique Terraform state bucket name."
  type        = string
  default     = "andreafalzetti-terraform-state-766515626185-eu-central-1"
}

variable "github_owner" {
  type    = string
  default = "andreafalzetti"
}

variable "github_owner_id" {
  description = "Immutable GitHub owner database ID used in OIDC subjects."
  type        = string
  default     = "2318450"
}

variable "github_repository" {
  type    = string
  default = "aws"
}

variable "github_repository_id" {
  description = "Immutable GitHub repository database ID used in OIDC subjects."
  type        = string
  default     = "1357333740"
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "gioco_github_repository" {
  type    = string
  default = "gioco"
}

variable "gioco_github_repository_id" {
  description = "Immutable GitHub database ID for andreafalzetti/gioco."
  type        = string
  default     = "1359391446"
}
