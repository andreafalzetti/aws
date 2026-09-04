#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_CONFIG="${ROOT_DIR}/config/project.env"

if [[ ! -f "${PROJECT_CONFIG}" ]]; then
  echo "Configurazione mancante: ${PROJECT_CONFIG}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${PROJECT_CONFIG}"

export AWS_PROFILE AWS_REGION
export AWS_DEFAULT_REGION="${AWS_REGION}"

if [[ -n "${CI:-}" ]] && command -v terraform >/dev/null 2>&1; then
  TF=(terraform)
elif command -v mise >/dev/null 2>&1; then
  TF=(mise exec -- terraform)
else
  TF=(terraform)
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Comando richiesto non trovato: $1" >&2
    exit 1
  fi
}

assert_aws_account() {
  require_command aws

  local actual_account
  actual_account="$(aws sts get-caller-identity --profile "${AWS_PROFILE}" --query Account --output text)"

  if [[ "${actual_account}" != "${AWS_ACCOUNT_ID}" ]]; then
    echo "Account AWS errato: atteso ${AWS_ACCOUNT_ID}, trovato ${actual_account}. Operazione interrotta." >&2
    exit 1
  fi
}
