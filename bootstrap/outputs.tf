output "github_actions_role_arn" {
  description = "Role assumed by GitHub Actions via OIDC."
  value       = aws_iam_role.github_actions.arn
}

output "gioco_github_actions_role_arn" {
  description = "Least-privilege role assumed by andreafalzetti/gioco GitHub Actions."
  value       = aws_iam_role.github_actions_gioco.arn
}

output "secrets_kms_key_arn" {
  description = "KMS key used for GitOps ciphertext and SSM SecureStrings."
  value       = aws_kms_key.terraform_secrets.arn
}

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}
