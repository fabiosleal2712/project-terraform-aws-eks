# Guia de CI/CD

## Configuração do Pipeline

1. **Checkout do Código**: Utilize a ação `actions/checkout@v2`.
2. **Configuração do Terraform**: Utilize a ação `hashicorp/setup-terraform@v1`.
3. **Execução do Terraform**: Execute os comandos `terraform init`, `terraform plan` e `terraform apply`.

## Estrutura do Pipeline

- **build**: Etapa de build e provisionamento dos recursos AWS.
- **test**: (Opcional) Adicione testes de integração.
- **deploy**: Deploy automático para o ambiente AWS configurado.

Para mais detalhes, consulte o arquivo `ci-cd/.github/workflows/main.yml`.
