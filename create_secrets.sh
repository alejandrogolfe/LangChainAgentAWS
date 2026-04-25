#!/bin/bash

# Lee las variables del .env
source .env

echo "Creando secrets en AWS Secrets Manager..."

aws secretsmanager create-secret \
  --name openai-api-key \
  --secret-string "$OPENAI_API_KEY"

aws secretsmanager create-secret \
  --name langchain-api-key \
  --secret-string "$LANGCHAIN_API_KEY"

echo "Done. Secrets creados:"
echo "  - openai-api-key"
echo "  - langchain-api-key"
echo ""
echo "LANGCHAIN_ENDPOINT, LANGCHAIN_PROJECT y LANGCHAIN_TRACING_V2"
echo "van como variables de entorno normales en el ecs.tf (no son secretas)"
