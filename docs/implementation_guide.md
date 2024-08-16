# Guia de Implementação

## Passos para Implementação

1. **Criar VPC**: Utilize o módulo VPC para criar subnets públicas e privadas.
2. **Configurar Firewall**: Configure Security Groups e NACLs.
3. **Implementar EC2**: Crie instâncias EC2 nas subnets públicas.
4. **Criar Cluster EKS**: Utilize o módulo EKS para criar um cluster Kubernetes.
5. **Implementar RDS**: Crie um banco de dados RDS nas subnets privadas.
6. **Gerenciar Segredos**: Utilize o AWS Secrets Manager para armazenar credenciais.
7. **Configurar CDN**: Implemente uma CDN para distribuição de conteúdo.
8. **Desenvolvimento e Deploy de Aplicação Open Source**:
   - Escolher uma aplicação open source para deployment (ex: Ghost Blog ou WordPress).
9. **Observabilidade e Escalabilidade**:
   - Configurar ferramentas de monitoramento e logging (ex: AWS CloudWatch, Prometheus, Grafana).
   - Implementar políticas de auto scaling para recursos EC2 e EKS.

## Detalhes dos Módulos

- **VPC**: Configuração de VPC com subnets públicas e privadas.
- **EC2**: Criação de instâncias EC2.
- **EKS**: Criação de cluster Kubernetes.
- **RDS**: Configuração de banco de dados relacional.
- **Secrets Manager**: Gestão de segredos.
- **CDN**: Configuração de Content Delivery Network.
- **Desenvolvimento e Deploy de Aplicação Open Source**: Escolha e deploy de uma aplicação open source.
- **Observabilidade e Escalabilidade**: Monitoramento, logging e auto scaling.

## Configuração de Ferramentas de Monitoramento e Logging

### AWS CloudWatch

1. **Configurar Logs**:
   - No console do AWS CloudWatch, crie um grupo de logs.
   - Configure suas instâncias EC2 e EKS para enviar logs para o grupo de logs criado.

2. **Configurar Métricas**:
   - Utilize o CloudWatch Agent para coletar métricas detalhadas de suas instâncias EC2.
   - Configure métricas customizadas para monitorar o desempenho de suas aplicações.

### Prometheus e Grafana

1. **Instalar Prometheus**:
   - Adicione o repositório Helm do Prometheus:
     ```sh
     helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
     helm repo update
     ```
   - Instale o Prometheus no seu cluster EKS:
     ```sh
     helm install prometheus prometheus-community/prometheus
     ```

2. **Instalar Grafana**:
   - Adicione o repositório Helm do Grafana:
     ```sh
     helm repo add grafana https://grafana.github.io/helm-charts
     helm repo update
     ```
   - Instale o Grafana no seu cluster EKS:
     ```sh
     helm install grafana grafana/grafana
     ```

3. **Configurar Datasources e Dashboards**:
   - Configure o Prometheus como datasource no Grafana.
   - Importe dashboards predefinidos ou crie dashboards customizados para visualizar as métricas coletadas.

Para mais detalhes, consulte a documentação oficial do [AWS CloudWatch](https://docs.aws.amazon.com/cloudwatch/) e do [Prometheus](https://prometheus.io/docs/introduction/overview/) e [Grafana](https://grafana.com/docs/).