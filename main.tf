provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true

  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "public_subnet_${count.index}"
    # Tags para EKS/ELB identificar subnets públicas
    "kubernetes.io/role/elb"                         = "1"
    "kubernetes.io/cluster/${var.cluster_name}"      = "shared"
  }
}

resource "aws_security_group" "main" {
  name        = "main_security_group"
  description = "Main security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Internet Gateway para VPC do EKS
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_igw"
  }
}

# Tabela de rotas pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "rds" {
  name        = "rds_security_group"
  description = "RDS security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "vpc" {
  source     = "./modules/vpc"
  cidr_block = var.vpc_cidr
  vpc_id     = var.vpc_id
  vpc_cidr   = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "ec2" {
  source = "./modules/ec2"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
  security_group_id = module.vpc.security_group_id
  ami_id = var.ami_id
  instance_type = var.instance_type
}

module "eks" {
  source = "./modules/eks"
  vpc_id = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id
  cluster_role_arn = aws_iam_role.eks_cluster_role.arn
  cluster_name = var.cluster_name
  security_group_ids = [aws_security_group.main.id]
  cluster_status = "ACTIVE"
  principal_arn = var.principal_arn
  node_role_arn = aws_iam_role.eks_node_role.arn
  node_group_name = "default-ng"
  node_instance_types = [var.instance_type]
  node_desired_size = 2
  node_min_size = 1
  node_max_size = 2
  node_disk_size = 20
  
  depends_on = [aws_iam_role.eks_cluster_role]
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

module "rds" {
  source = "./modules/rds"
  vpc_id = module.vpc.vpc_id
  subnet_ids = [
    module.vpc.private_subnet_a_id,
    module.vpc.private_subnet_b_id,
    module.vpc.private_subnet_c_id
  ]
  security_group_id = module.vpc.security_group_id  
  db_password = var.db_password
}

module "secrets_manager" {
  source = "./modules/secrets_manager"
  db_password = var.db_password
}

module "cdn" {
  source = "./modules/cdn"
  origin_domain_name = "my-valid-s3-bucket.s3.amazonaws.com"
}

# ECRs para os microserviços .NET do projeto nutri-veda
module "ecr" {
  source = "./modules/ecr"
  repositories = [
    "adm-dashboard-webapp",
    "chat-api",
    "diary-api",
    "migrations-api",
    "schedulings-api",
    "systemsettings-api",
    "users-api",
    "nutri-veda-webapp"
  ]
}

# Temporariamente desabilitado até o cluster EKS estar funcionando
# module "prometheus" {
#   source = "./modules/prometheus"
#   
#   providers = {
#     kubernetes.k8s = kubernetes
#   }
#
#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets
# }

# module "grafana" {
#   source = "./modules/grafana"
#   
#   providers = {
#     kubernetes.k8s = kubernetes
#   }
#
#   vpc_id = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets
#   depends_on = [module.eks]
# }