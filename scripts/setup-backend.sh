#!/usr/bin/env bash
set -euo pipefail

# Creates S3 + DynamoDB remote backend for Terraform state
# Requirements: aws cli v2, valid AWS credentials, permissions to create S3/DDB

PROJECT="procode-cloud"
ENV="dev"
REGION="eu-west-2"
STATE_KEY="ecs-deployment/terraform.tfstate"

usage() {
  cat <<EOF
Usage:
  ./scripts/setup-backend.sh [-p <project>] [-e <env>] [-r <region>] [-k <state_key>]

Defaults:
  project   = ${PROJECT}
  env       = ${ENV}
  region    = ${REGION}
  state_key = ${STATE_KEY}

Example:
  ./scripts/setup-backend.sh -p procode-cloud -e dev -r eu-west-2
EOF
}

while getopts ":p:e:r:k:h" opt; do
  case "${opt}" in
    p) PROJECT="${OPTARG}" ;;
    e) ENV="${OPTARG}" ;;
    r) REGION="${OPTARG}" ;;
    k) STATE_KEY="${OPTARG}" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -${OPTARG}" >&2; usage; exit 1 ;;
    :) echo "Option -${OPTARG} requires an argument." >&2; usage; exit 1 ;;
  esac
done

# Bucket naming must be globally unique
BUCKET="${PROJECT}-tfstate-${ENV}"
DDB_TABLE="${PROJECT}-tflocks-${ENV}"

echo "Region:  ${REGION}"
echo "Bucket:  ${BUCKET}"
echo "DDB:     ${DDB_TABLE}"
echo "Key:     ${STATE_KEY}"
echo

# --------
# Create S3 bucket
# --------
echo ">> Ensuring S3 bucket exists..."

# head-bucket can fail even if bucket exists (e.g., not owned). Try it, then handle create carefully.
if aws s3api head-bucket --bucket "${BUCKET}" --region "${REGION}" >/dev/null 2>&1; then
  echo "   Bucket already exists and is accessible."
else
  echo "   Bucket not found or not accessible; attempting to create..."

  if [[ "${REGION}" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "${BUCKET}" \
      --region "${REGION}"
  else
    aws s3api create-bucket \
      --bucket "${BUCKET}" \
      --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi

  echo "   Bucket created."
fi

echo ">> Applying bucket hardening (public access block, versioning, encryption)..."

aws s3api put-public-access-block \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

aws s3api put-bucket-versioning \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" }
      }
    ]
  }'

# Optional but nice: enforce TLS for S3 API access
echo ">> Applying bucket policy (deny non-TLS)..."
cat > /tmp/tfstate-bucket-policy.json <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${BUCKET}",
        "arn:aws:s3:::${BUCKET}/*"
      ],
      "Condition": {
        "Bool": { "aws:SecureTransport": "false" }
      }
    }
  ]
}
POLICY

aws s3api put-bucket-policy \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --policy file:///tmp/tfstate-bucket-policy.json

# --------
# Create DynamoDB lock table
# --------
echo ">> Ensuring DynamoDB lock table exists..."
if aws dynamodb describe-table --table-name "${DDB_TABLE}" --region "${REGION}" >/dev/null 2>&1; then
  echo "   DynamoDB table already exists."
else
  aws dynamodb create-table \
    --table-name "${DDB_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}" >/dev/null

  echo "   Table created. Waiting until ACTIVE..."
  aws dynamodb wait table-exists --table-name "${DDB_TABLE}" --region "${REGION}"
fi

# --------
# Write backend.hcl
# --------
echo ">> Writing backend.hcl..."
cat > backend.hcl <<EOF
bucket         = "${BUCKET}"
key            = "${STATE_KEY}"
region         = "${REGION}"
encrypt        = true
dynamodb_table = "${DDB_TABLE}"
EOF

echo
echo "Done."

echo
echo "GitHub Actions variables to set:"
echo "  AWS_REGION=${REGION}"
echo "  TF_STATE_BUCKET=${BUCKET}"
echo "  TF_STATE_KEY=${STATE_KEY}"
echo "  TF_STATE_DDB_TABLE=${DDB_TABLE}"
