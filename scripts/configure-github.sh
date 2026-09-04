#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_command gh
assert_aws_account

gh auth status >/dev/null

role_arn="$("${TF[@]}" -chdir="${ROOT_DIR}/bootstrap" output -raw github_actions_role_arn)"

gh variable set AWS_ACCOUNT_ID --repo "${GITHUB_REPOSITORY}" --body "${AWS_ACCOUNT_ID}"
gh variable set AWS_REGION --repo "${GITHUB_REPOSITORY}" --body "${AWS_REGION}"
gh variable set TF_STATE_BUCKET --repo "${GITHUB_REPOSITORY}" --body "${TF_STATE_BUCKET}"
gh variable set AWS_ROLE_ARN --repo "${GITHUB_REPOSITORY}" --body "${role_arn}"

echo "GitHub Actions configurato tramite OIDC; non sono state create access key o GitHub secrets."
