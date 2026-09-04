#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

"${TF[@]}" fmt -check -recursive "${ROOT_DIR}"

for script in "${ROOT_DIR}"/scripts/*.sh; do
  bash -n "${script}"
done

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/aws-terraform-check.XXXXXX")"
trap 'rm -rf "${temp_dir}"' EXIT INT TERM

for stack in bootstrap environments/production; do
  data_dir="${temp_dir}/${stack//\//-}"
  mkdir -p "${data_dir}"
  TF_DATA_DIR="${data_dir}" "${TF[@]}" -chdir="${ROOT_DIR}/${stack}" init -backend=false -input=false >/dev/null
  TF_DATA_DIR="${data_dir}" "${TF[@]}" -chdir="${ROOT_DIR}/${stack}" validate
done

echo "Controlli completati."
