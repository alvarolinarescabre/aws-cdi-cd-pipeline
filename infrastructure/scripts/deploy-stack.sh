#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_FILE="$REPO_ROOT/cloudformation/stack.yml"

STACK_NAME="${1:-api-stack}"
IMAGE_URI="${2:-}"
REGION="${AWS_REGION:-us-east-1}"

if [ -z "$IMAGE_URI" ]; then
  echo "Usage: $0 <stack-name> <container-image-uri>"
  echo "Example: $0 api-stack 123456789012.dkr.ecr.us-east-1.amazonaws.com/api:latest"
  exit 1
fi

echo "Desplegando la pila CloudFormation '$STACK_NAME' en $REGION con imagen '$IMAGE_URI'"

aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ContainerImage="$IMAGE_URI"

echo "Despliegue finalizado. Para ver los outputs ejecuta:"
echo "aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs'"
