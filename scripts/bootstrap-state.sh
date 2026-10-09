#!/usr/bin/env bash
# Creates the S3 bucket that holds Terraform state. Safe to run more than once.
set -euo pipefail

export AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

if aws s3api head-bucket --bucket tfstate 2>/dev/null; then
  echo "State bucket already exists"
else
  aws s3api create-bucket --bucket tfstate
  aws s3api put-bucket-versioning --bucket tfstate \
    --versioning-configuration Status=Enabled
  echo "State bucket created"
fi