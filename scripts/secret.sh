#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

MANIFEST="${ROOT_DIR}/environments/production/secrets.auto.tfvars.json"
KMS_ALIAS="alias/terraform-secrets"
ALLOWED_SSM_PREFIXES=(
  "/crm-demo/production/"
  "/n8n-demo/production/"
  "/platform/production/"
)

usage() {
  cat >&2 <<'EOF'
Uso:
  scripts/secret.sh list
  scripts/secret.sh add <chiave-logica> </workload/production/percorso> [--stdin]
  scripts/secret.sh rotate <chiave-logica> [--stdin]

Senza --stdin il valore viene richiesto due volte con input nascosto.
Con --stdin viene letta una singola riga, utile con: op read -n ... | scripts/secret.sh ... --stdin
EOF
  exit 2
}

read_secret() {
  local mode="${1:-}"
  local first second

  if [[ "${mode}" == "--stdin" ]]; then
    IFS= read -r first || [[ -n "${first}" ]]
  elif [[ -z "${mode}" ]]; then
    [[ -t 0 ]] || {
      echo "Input non interattivo: specifica --stdin." >&2
      exit 2
    }
    IFS= read -r -s -p "Valore segreto: " first
    echo >&2
    IFS= read -r -s -p "Conferma: " second
    echo >&2
    [[ "${first}" == "${second}" ]] || {
      echo "I valori non coincidono." >&2
      exit 1
    }
  else
    usage
  fi

  [[ -n "${first}" ]] || {
    echo "Il valore non può essere vuoto." >&2
    exit 1
  }

  printf '%s' "${first}"
}

list_secrets() {
  jq -r '
    .encrypted_parameters
    | to_entries[]?
    | "\(.key)\tversion=\(.value.version)\t\(.value.name)"
  ' "${MANIFEST}"
}

is_allowed_ssm_path() {
  local parameter_name="$1"
  local prefix

  for prefix in "${ALLOWED_SSM_PREFIXES[@]}"; do
    [[ "${parameter_name}" == "${prefix}"* ]] && return 0
  done

  return 1
}

write_ciphertext() {
  local operation="$1"
  local logical_key="$2"
  local parameter_name="$3"
  local input_mode="${4:-}"

  [[ "${logical_key}" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || {
    echo "Chiave logica non valida: usa minuscole, numeri, _ o -." >&2
    exit 2
  }
  local existing
  existing="$(jq -r --arg key "${logical_key}" '.encrypted_parameters[$key] // empty | .name // empty' "${MANIFEST}")"

  if [[ "${operation}" == "add" && -n "${existing}" ]]; then
    echo "${logical_key} esiste già; usa rotate." >&2
    exit 1
  fi
  if [[ "${operation}" == "rotate" ]]; then
    [[ -n "${existing}" ]] || {
      echo "${logical_key} non esiste; usa add." >&2
      exit 1
    }
    parameter_name="${existing}"
  fi

  is_allowed_ssm_path "${parameter_name}" || {
    echo "Path SSM non consentito. Prefix ammessi: ${ALLOWED_SSM_PREFIXES[*]}" >&2
    exit 2
  }

  umask 077
  local secret_file manifest_file
  secret_file="$(mktemp "${TMPDIR:-/tmp}/aws-secret-plaintext.XXXXXX")"
  manifest_file="$(mktemp "${TMPDIR:-/tmp}/aws-secret-manifest.XXXXXX")"
  cleanup() {
    rm -f "${secret_file}" "${manifest_file}"
  }
  trap cleanup EXIT INT TERM

  read_secret "${input_mode}" >"${secret_file}"

  local ciphertext current_version next_version workload
  ciphertext="$(aws kms encrypt \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --key-id "${KMS_ALIAS}" \
    --plaintext "fileb://${secret_file}" \
    --encryption-context "ssm_parameter_name=${parameter_name}" \
    --query CiphertextBlob \
    --output text)"

  : >"${secret_file}"

  current_version="$(jq -r --arg key "${logical_key}" '.encrypted_parameters[$key].version // 0' "${MANIFEST}")"
  next_version=$((current_version + 1))
  workload="${parameter_name#/}"
  workload="${workload%%/*}"

  jq \
    --arg key "${logical_key}" \
    --arg name "${parameter_name}" \
    --arg ciphertext "${ciphertext}" \
    --arg workload "${workload}" \
    --argjson version "${next_version}" \
    '.encrypted_parameters[$key] = {
      name: $name,
      description: ("External secret managed as KMS ciphertext: " + $key),
      ciphertext: $ciphertext,
      version: $version,
      tags: {Workload: $workload}
    }' "${MANIFEST}" >"${manifest_file}"

  mv "${manifest_file}" "${MANIFEST}"
  chmod 0644 "${MANIFEST}"
  trap - EXIT INT TERM
  rm -f "${secret_file}"

  echo "Registrato ${logical_key} -> ${parameter_name}, versione ${next_version}. Nel repository c'è soltanto ciphertext KMS."
}

require_command jq
assert_aws_account

[[ -f "${MANIFEST}" ]] || {
  echo "Manifest mancante: ${MANIFEST}" >&2
  exit 1
}

case "${1:-}" in
  list)
    [[ $# -eq 1 ]] || usage
    list_secrets
    ;;
  add)
    [[ $# -ge 3 && $# -le 4 ]] || usage
    write_ciphertext add "$2" "$3" "${4:-}"
    ;;
  rotate)
    [[ $# -ge 2 && $# -le 3 ]] || usage
    write_ciphertext rotate "$2" "unused" "${3:-}"
    ;;
  *)
    usage
    ;;
esac
