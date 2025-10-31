#!/usr/bin/env bash
set -euo pipefail

# Build de todas as imagens Docker dos microserviços
# Uso: ./scripts/build-all-services.sh [caminho-para-nutri-veda]
# Exemplo: ./scripts/build-all-services.sh ../nutri-veda

NUTRI_VEDA_PATH="${1:-../nutri-veda}"
TAG="${2:-1.0.0}"

if [ ! -d "$NUTRI_VEDA_PATH" ]; then
  echo "❌ Diretório $NUTRI_VEDA_PATH não encontrado." >&2
  echo "Uso: $0 [caminho-para-nutri-veda] [tag]" >&2
  exit 1
fi

# Diretório onde estão os Dockerfiles (projeto terraform)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

echo "🏗️  Iniciando build de todas as imagens..."
echo "📁 Contexto: $(realpath "$NUTRI_VEDA_PATH")"
echo "📂 Dockerfiles: $TERRAFORM_DIR"
echo "🏷️  Tag: $TAG"
echo ""

# Array com todos os serviços (nome:dockerfile)
declare -A SERVICES=(
  ["adm-dashboard-webapp"]="Dockerfile.adm.dashboard.webapp"
  ["chat-api"]="Dockerfile.chat.api"
  ["diary-api"]="Dockerfile.diary.api"
  ["migrations-api"]="Dockerfile.migrations.api"
  ["schedulings-api"]="Dockerfile.schedulings.api"
  ["systemsettings-api"]="Dockerfile.systemsettings.api"
  ["users-api"]="Dockerfile.users.api"
  ["webapp"]="Dockerfile.webapp"
)

SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_SERVICES=()

for SERVICE in "${!SERVICES[@]}"; do
  DOCKERFILE="${SERVICES[$SERVICE]}"
  IMAGE_NAME="$SERVICE"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔨 Building: $IMAGE_NAME:$TAG"
  echo "📄 Dockerfile: $DOCKERFILE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  DOCKERFILE_PATH="$TERRAFORM_DIR/$DOCKERFILE"
  if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "⚠️  Dockerfile $DOCKERFILE_PATH não encontrado. Pulando..."
    ((FAILED_COUNT++))
    FAILED_SERVICES+=("$SERVICE (Dockerfile não encontrado)")
    continue
  fi
  
  # Build no contexto do nutri-veda, mas usando o Dockerfile do projeto terraform
  if docker build -t "$IMAGE_NAME:$TAG" -f "$DOCKERFILE_PATH" "$NUTRI_VEDA_PATH"; then
    echo "✅ Build concluído: $IMAGE_NAME:$TAG"
    ((SUCCESS_COUNT++))
  else
    echo "❌ Falha no build: $IMAGE_NAME:$TAG"
    ((FAILED_COUNT++))
    FAILED_SERVICES+=("$SERVICE")
  fi
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESUMO DO BUILD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Sucesso: $SUCCESS_COUNT"
echo "❌ Falhas: $FAILED_COUNT"

if [ ${#FAILED_SERVICES[@]} -gt 0 ]; then
  echo ""
  echo "Serviços com falha:"
  for FAILED in "${FAILED_SERVICES[@]}"; do
    echo "  - $FAILED"
  done
fi

echo ""
echo "🎯 Imagens construídas:"
docker images | grep -E "(adm-dashboard-webapp|chat-api|diary-api|migrations-api|schedulings-api|systemsettings-api|users-api|webapp)" | grep "$TAG" || echo "  (nenhuma imagem encontrada com tag $TAG)"

if [ $FAILED_COUNT -eq 0 ]; then
  echo ""
  echo "🎉 Todas as imagens foram construídas com sucesso!"
  exit 0
else
  echo ""
  echo "⚠️  Algumas imagens falharam. Verifique os logs acima."
  exit 1
fi
