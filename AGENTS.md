# Repository guardrails

- This repository belongs to Andrea's personal AWS account. Never use OFC AWS profiles, accounts, KMS keys, secrets, paths, or naming here.
- Local AWS operations must use the `andrea` profile and must verify account `766515626185` before mutating anything.
- Never commit plaintext secrets, Terraform state, saved plans, credentials, or decrypted SSM values.
- `bootstrap/` is intentionally local-admin only. GitHub Actions may apply only `environments/production/` and must not be granted permission to change its own IAM role or policy.
- Prefer SSM `SecureString` parameters with `value_wo`; secret plaintext must not enter Terraform plans or state.
- Preserve the exact OIDC subject restriction for `andreafalzetti/aws` on `main` unless the trust model is deliberately redesigned.
- Keep workloads isolated by SSM namespace. Every new namespace must be explicitly allowlisted in both the CI IAM policy and the local secret CLI.
