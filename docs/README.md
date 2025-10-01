# Projeto Infra AWS com OpenTofu + EKS

Este repositório provisiona uma stack AWS moderna usando OpenTofu (compatível com Terraform):

- VPC com subnets públicas/privadas, IGW e rotas públicas
- EKS (Kubernetes 1.30) com Managed Node Group
- RDS PostgreSQL 16
- ECR por microserviço
- Secrets Manager e CDN (CloudFront)
- Manifests Kubernetes base e fluxo para carregar imagens locais no nó EKS (sem push no registry)

## Estrutura do Repositório

- Arquivos de IaC na raiz: `main.tf`, `variables.tf`, `versions.tf`, `provider.tf`, `outputs.tf`
- Módulos: `modules/` (vpc, eks, rds, ecr, etc.)
- Kubernetes: `k8s/` (namespace, templates de deployment/service/ingress, smoke test nginx)
- Scripts: `scripts/` (carga de imagem local via SSM + geração de Secret do DB)
- App exemplo: `nutri-veda/` (código .NET e Dockerfiles)
- Documentação: `docs/`

## Como executar (resumo)

1) Pré-requisitos: OpenTofu, AWS CLI v2, kubectl
2) Configure credenciais AWS (perfil default) e `terraform.tfvars` conforme `terraform.tfvars.example`
3) `tofu init && tofu apply`
4) Atualize kubeconfig via AWS CLI e valide `kubectl get nodes`
5) Aplique `k8s/namespace.yaml` e o smoke test `k8s/nginx-smoke.yaml`
6) Para publicar um serviço local sem ECR: use `scripts/apply-db-secret.sh` e `scripts/load-image-to-eks-node.sh`

Detalhes passo a passo no `implementation_guide.md` e `ci_cd_guide.md`.
