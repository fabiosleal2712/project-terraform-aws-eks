# Guia Completo: Deploy de Todos os Microserviços

Este guia mostra como fazer build e deploy dos 8 microserviços (7 APIs + 2 Web Apps) no EKS.

## Pré-requisitos

- Infraestrutura provisionada (tofu apply concluído)
- kubectl configurado (aws eks update-kubeconfig)
- Docker instalado e rodando
- Bucket S3 temporário criado
- Secret db-conn aplicada no cluster

## Estrutura dos Serviços

Os 8 microserviços são:

1. **chat-api** - Sistema de chat/mensagens
2. **diary-api** - Gerenciamento de diários
3. **migrations-api** - Migrações de dados
4. **schedulings-api** - Agendamentos
5. **systemsettings-api** - Configurações do sistema
6. **users-api** - Gerenciamento de usuários
7. **webapp** - Aplicação web principal
8. **adm-dashboard-webapp** - Painel administrativo

## Opção 1: Deploy Automatizado (Recomendado)

### Passo 1: Build de Todas as Imagens

```bash
# No diretório do projeto terraform
cd /home/fabioleal/github/project-terraform-aws-eks

# Executar build (ajuste o caminho para nutri-veda se necessário)
chmod +x scripts/build-all-services.sh
./scripts/build-all-services.sh ../nutri-veda 1.0.0
```

**O que o script faz:**
- Varre todos os Dockerfiles
- Faz build de cada imagem com tag 1.0.0
- Mostra progresso e resumo ao final
- Lista imagens com falha (se houver)

### Passo 2: Aplicar Secret do Banco

```bash
# Aplicar a Secret com as credenciais do RDS
DB_NAME=mydb DB_USER=postgres DB_PASSWORD='SUA_SENHA' \
  ./scripts/apply-db-secret.sh nutri-veda
```

### Passo 3: Deploy Automatizado

```bash
# Definir bucket temporário
export BUCKET_TEMP=fabioleal-eks-images-$(date +%Y%m%d)

# Criar bucket se não existir
aws s3 mb s3://$BUCKET_TEMP || true

# Executar deploy de todos os serviços
chmod +x scripts/deploy-all-services.sh
./scripts/deploy-all-services.sh my-test-cluster nutri-veda 1.0.0
```

**O que o script faz:**
- Aplica todos os manifests Kubernetes
- Para cada serviço:
  - Carrega a imagem no nó via SSM
  - Reinicia o pod
  - Aguarda o rollout completar
- Mostra resumo ao final

### Passo 4: Verificar Status

```bash
# Listar todos os pods
kubectl -n nutri-veda get pods -o wide

# Ver logs de um serviço específico
kubectl -n nutri-veda logs -l app=users-api --tail=50

# Ver todos os serviços
kubectl -n nutri-veda get svc
```

## Opção 2: Deploy Manual (Serviço por Serviço)

Se preferir controle total, você pode deployar cada serviço individualmente:

### Build Individual

```bash
cd ../nutri-veda

# Exemplo: chat-api
docker build -t chat-api:1.0.0 -f Dockerfile.chat.api .

# Exemplo: users-api
docker build -t users-api:1.0.0 -f Dockerfile.users.api .

# Listar imagens construídas
docker images | grep "1.0.0"
```

### Deploy Individual

```bash
# Aplicar manifest
kubectl apply -f k8s/chat-api.yaml -n nutri-veda

# Carregar imagem no nó
export BUCKET_TEMP=SEU_BUCKET
./scripts/load-image-to-eks-node.sh my-test-cluster nutri-veda app=chat-api chat-api 1.0.0

# Reiniciar pod
kubectl -n nutri-veda delete pod -l app=chat-api

# Acompanhar rollout
kubectl -n nutri-veda rollout status deploy/chat-api
```

Repita para cada serviço (diary-api, migrations-api, etc.)

## Troubleshooting

### Pod Pending por Capacidade

Se muitos pods ficarem Pending com "Too many pods":

```bash
# Aumentar Node Group no main.tf
# node_desired_size = 3  # ou mais
# node_max_size = 5

# Aplicar mudança
tofu apply -auto-approve

# Aguardar nós ficarem Ready
kubectl get nodes -w
```

### Imagem não encontrada (ErrImageNeverPull)

```bash
# Verificar se a imagem existe localmente
docker images | grep NOME_DO_SERVICO

# Se não existir, fazer build
cd ../nutri-veda
docker build -t NOME_DO_SERVICO:1.0.0 -f Dockerfile.NOME .

# Carregar novamente no nó
./scripts/load-image-to-eks-node.sh my-test-cluster nutri-veda app=NOME NOME 1.0.0
```

### Secret não encontrada

```bash
# Verificar se existe
kubectl -n nutri-veda get secret db-conn

# Se não existir, aplicar
DB_NAME=mydb DB_USER=postgres DB_PASSWORD='SENHA' \
  ./scripts/apply-db-secret.sh nutri-veda
```

### Pod CrashLoopBackOff

```bash
# Ver logs do pod
kubectl -n nutri-veda logs -l app=NOME_DO_SERVICO --tail=100

# Ver eventos
kubectl -n nutri-veda describe pod -l app=NOME_DO_SERVICO

# Possíveis causas:
# - Conexão com banco (verificar Secret e endpoint)
# - Porta incorreta (deve ser 8080)
# - Variável de ambiente faltando
```

## Comandos Úteis

### Monitoramento

```bash
# Ver todos os pods em tempo real
kubectl -n nutri-veda get pods -w

# Ver pods com mais detalhes
kubectl -n nutri-veda get pods -o wide

# Ver recursos consumidos
kubectl -n nutri-veda top pods
```

### Logs Agregados

```bash
# Logs de todos os pods de um deployment
kubectl -n nutri-veda logs -l app=users-api --all-containers=true

# Seguir logs em tempo real
kubectl -n nutri-veda logs -l app=users-api -f
```

### Escalar Manualmente

```bash
# Aumentar réplicas de um serviço
kubectl -n nutri-veda scale deploy/users-api --replicas=2

# Voltar para 1
kubectl -n nutri-veda scale deploy/users-api --replicas=1
```

### Limpar e Recomeçar

```bash
# Deletar todos os pods (vão recriar automaticamente)
kubectl -n nutri-veda delete pods --all

# Deletar todos os deployments
kubectl -n nutri-veda delete deploy --all

# Reaplicar tudo
kubectl apply -f k8s/ -n nutri-veda
```

## Ordem Recomendada de Deploy

Para evitar problemas de dependência, considere esta ordem:

1. **migrations-api** - Executar migrações primeiro
2. **users-api** - Sistema de autenticação
3. **systemsettings-api** - Configurações base
4. **chat-api** - Funcionalidades de chat
5. **diary-api** - Funcionalidades de diário
6. **schedulings-api** - Agendamentos
7. **webapp** - Interface do usuário
8. **adm-dashboard-webapp** - Painel admin

## Próximos Passos

Após todos os serviços estarem rodando:

1. **Expor externamente** - Instalar AWS Load Balancer Controller
2. **Monitoramento** - Reativar Prometheus/Grafana
3. **CI/CD** - Configurar pipeline GitHub Actions
4. **Health Checks** - Adicionar liveness/readiness probes
5. **Logs Centralizados** - Configurar CloudWatch ou ELK

## Resumo Rápido (Copy-Paste)

```bash
# 1. Build
cd /home/fabioleal/github/project-terraform-aws-eks
./scripts/build-all-services.sh ../nutri-veda 1.0.0

# 2. Secret
DB_NAME=mydb DB_USER=postgres DB_PASSWORD='SENHA' \
  ./scripts/apply-db-secret.sh nutri-veda

# 3. Deploy
export BUCKET_TEMP=fabioleal-eks-images-$(date +%Y%m%d)
aws s3 mb s3://$BUCKET_TEMP || true
./scripts/deploy-all-services.sh my-test-cluster nutri-veda 1.0.0

# 4. Verificar
kubectl -n nutri-veda get pods -o wide
```
