#!/bin/bash

set -Eeuo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

assert_aws_account

if aws s3api head-bucket --profile "${AWS_PROFILE}" --bucket "${TF_STATE_BUCKET}" >/dev/null 2>&1; then
  bucket_region="$(aws s3api get-bucket-location \
    --profile "${AWS_PROFILE}" \
    --bucket "${TF_STATE_BUCKET}" \
    --query 'LocationConstraint' \
    --output text)"

  [[ "${bucket_region}" == "None" ]] && bucket_region="us-east-1"

  if [[ "${bucket_region}" != "${AWS_REGION}" ]]; then
    echo "Il bucket esiste in ${bucket_region}, non in ${AWS_REGION}. Operazione interrotta." >&2
    exit 1
  fi

  echo "Bucket state già presente: ${TF_STATE_BUCKET}"
else
  echo "Creo il bucket state ${TF_STATE_BUCKET} in ${AWS_REGION}..."
  if [[ "${AWS_REGION}" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --profile "${AWS_PROFILE}" \
      --region "${AWS_REGION}" \
      --bucket "${TF_STATE_BUCKET}" >/dev/null
  else
    aws s3api create-bucket \
      --profile "${AWS_PROFILE}" \
      --region "${AWS_REGION}" \
      --bucket "${TF_STATE_BUCKET}" \
      --create-bucket-configuration "LocationConstraint=${AWS_REGION}" >/dev/null
  fi
fi

aws s3api put-public-access-block \
  --profile "${AWS_PROFILE}" \
  --bucket "${TF_STATE_BUCKET}" \
  --public-access-block-configuration \
  'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'

aws s3api put-bucket-ownership-controls \
  --profile "${AWS_PROFILE}" \
  --bucket "${TF_STATE_BUCKET}" \
  --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]'

aws s3api put-bucket-versioning \
  --profile "${AWS_PROFILE}" \
  --bucket "${TF_STATE_BUCKET}" \
  --versioning-configuration 'Status=Enabled'

# KMS viene applicato subito dopo dallo stack bootstrap. Questa cifratura copre
# anche l'intervallo iniziale precedente alla creazione della chiave dedicata.
aws s3api put-bucket-encryption \
  --profile "${AWS_PROFILE}" \
  --bucket "${TF_STATE_BUCKET}" \
  --server-side-encryption-configuration \
  'Rules=[{ApplyServerSideEncryptionByDefault={SSEAlgorithm=AES256},BucketKeyEnabled=true}]'

aws s3api put-bucket-tagging \
  --profile "${AWS_PROFILE}" \
  --bucket "${TF_STATE_BUCKET}" \
  --tagging 'TagSet=[{Key=ManagedBy,Value=terraform},{Key=Project,Value=andreafalzetti-aws},{Key=Purpose,Value=terraform-state}]'

echo "Bucket state pronto; versioning, ownership e blocco accesso pubblico sono attivi."
