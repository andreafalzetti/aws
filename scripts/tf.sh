#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  echo "Uso: $0 <bootstrap|production> <terraform-command> [argomenti...]" >&2
  exit 2
}

[[ $# -ge 2 ]] || usage

stack="$1"
command="$2"
shift 2

case "${stack}" in
  bootstrap)
    stack_dir="${ROOT_DIR}/bootstrap"
    ;;
  production)
    stack_dir="${ROOT_DIR}/environments/production"
    ;;
  *)
    usage
    ;;
esac

assert_aws_account

export TF_VAR_aws_account_id="${AWS_ACCOUNT_ID}"
export TF_VAR_aws_region="${AWS_REGION}"

if [[ "${command}" == "init" ]]; then
  exec "${TF[@]}" -chdir="${stack_dir}" init \
    -reconfigure \
    -backend-config=backend.hcl \
    "$@"
fi

exec "${TF[@]}" -chdir="${stack_dir}" "${command}" "$@"
