#!/usr/bin/env bash
set -euo pipefail

# Deploy de todos os microserviços no EKS
# Carrega imagens locais nos nós via SSM e aplica os manifests Kubernetes
# Uso: ./scripts/deploy-all-services.sh <cluster-name> <namespace> [tag]
# Exemplo: BUCKET_TEMP=meu-bucket ./scripts/deploy-all-services.sh my-test-cluster nutri-veda 1.0.0

if [ "$#" -lt 2 ]; then
  echo "Uso: $0 <cluster-name> <namespace> [tag]" >&2
  echo "Requer também BUCKET_TEMP definido no ambiente" >&2
  exit 1
fi

CLUSTER_NAME="$1"
NAMESPACE="$2"
TAG="${3:-1.0.0}"

if [ -z "${BUCKET_TEMP:-}" ]; then
  echo "❌ Defina BUCKET_TEMP com um bucket S3 temporário." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Array com todos os serviços (nome:selector)
declare -A SERVICES=(
  ["adm-dashboard-webapp"]="app=adm-dashboard-webapp"
  ["chat-api"]="app=chat-api"
  ["diary-api"]="app=diary-api"
  ["migrations-api"]="app=migrations-api"
  ["schedulings-api"]="app=schedulings-api"
  ["systemsettings-api"]="app=systemsettings-api"
  ["users-api"]="app=users-api"
  ["webapp"]="app=webapp"
)

echo "🚀 Iniciando deploy de todos os serviços"
echo "🎯 Cluster: $CLUSTER_NAME"
echo "📦 Namespace: $NAMESPACE"
echo "🏷️  Tag: $TAG"
echo "🪣 S3 Bucket: $BUCKET_TEMP"
echo ""

SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_SERVICES=()

# 1) Aplicar todos os manifests primeiro
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Aplicando manifests Kubernetes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Aplicar apenas os yamls de serviços específicos (não os templates)
kubectl apply -f "$SCRIPT_DIR/../k8s/namespace.yaml" -n "$NAMESPACE" 2>/dev/null || true
for svc_file in "$SCRIPT_DIR/../k8s/"*.yaml; do
  filename=$(basename "$svc_file")
  # Pular templates e outros arquivos que não são deployments reais
  if [[ ! "$filename" =~ (template|example|nginx-smoke) ]]; then
    kubectl apply -f "$svc_file" -n "$NAMESPACE" || true
  fi
done
echo ""

# 2) Aguardar pods serem agendados
echo "⏳ Aguardando pods serem agendados nos nós..."
sleep 10
echo ""

# 3) Carregar imagens e reiniciar pods
for SERVICE in "${!SERVICES[@]}"; do
  SELECTOR="${SERVICES[$SERVICE]}"
  IMAGE_NAME="$SERVICE"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔄 Deploying: $SERVICE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Verificar se o pod já está Running
  POD_STATUS=$(kubectl -n "$NAMESPACE" get pods -l "$SELECTOR" -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "")
  if [ "$POD_STATUS" = "Running" ]; then
    echo "✅ Serviço já está Running. Pulando..."
    ((SUCCESS_COUNT++))
    continue
  fi
  
  # Verifica se a imagem local existe
  if ! docker image inspect "$IMAGE_NAME:$TAG" >/dev/null 2>&1; then
    echo "⚠️  Imagem $IMAGE_NAME:$TAG não encontrada localmente. Pulando..."
    ((FAILED_COUNT++))
    FAILED_SERVICES+=("$SERVICE (imagem não encontrada)")
    continue
  fi
  
  # Carrega imagem no nó
  echo "📤 Carregando imagem $IMAGE_NAME:$TAG no nó..."
  if "$SCRIPT_DIR/load-image-to-eks-node.sh" "$CLUSTER_NAME" "$NAMESPACE" "$SELECTOR" "$IMAGE_NAME" "$TAG"; then
    echo "✅ Imagem carregada com sucesso"
    
    # Reinicia o pod
    echo "🔄 Reiniciando pod..."
    kubectl -n "$NAMESPACE" delete pod -l "$SELECTOR" --ignore-not-found=true
    
    # Aguarda rollout
    echo "⏳ Aguardando rollout..."
    if kubectl -n "$NAMESPACE" rollout status deploy/"$SERVICE" --timeout=300s; then
      echo "✅ Deploy concluído: $SERVICE"
      ((SUCCESS_COUNT++))
    else
      echo "⚠️ Timeout no rollout: $SERVICE"
      echo "📋 Verificando status do pod..."
      kubectl -n "$NAMESPACE" get pods -l "$SELECTOR" -o wide
      kubectl -n "$NAMESPACE" describe pod -l "$SELECTOR" | tail -20
      ((FAILED_COUNT++))
      FAILED_SERVICES+=("$SERVICE (timeout no rollout)")
    fi
  else
    echo "❌ Falha ao carregar imagem: $SERVICE"
    ((FAILED_COUNT++))
    FAILED_SERVICES+=("$SERVICE (falha no load)")
  fi
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESUMO DO DEPLOY"
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
echo "📦 Status dos pods:"
kubectl -n "$NAMESPACE" get pods -o wide

if [ $FAILED_COUNT -eq 0 ]; then
  echo ""
  echo "🎉 Todos os serviços foram deployados com sucesso!"
  exit 0
else
  echo ""
  echo "⚠️  Alguns serviços falharam. Verifique os logs acima."
  exit 1
fi
