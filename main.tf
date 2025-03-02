provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "us-east-1"
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

  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "public_subnet_${count.index}"
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
  security_group_id = aws_security_group.main.id
  ami_id = var.ami_id
  instance_type = var.instance_type
}

module "eks" {
  source = "./modules/eks"
  vpc_id = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id
  cluster_role_arn = var.cluster_role_arn
  cluster_name = var.cluster_name
  security_group_ids = [aws_security_group.main.id]
  cluster_status = "ACTIVE"
  principal_arn = var.principal_arn
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
  security_group_id = aws_security_group.rds.id  
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

module "prometheus" {
  source = "./modules/prometheus"
  
  providers = {
    kubernetes.k8s = kubernetes
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

module "grafana" {
  source = "./modules/grafana"
  
  providers = {
    kubernetes.k8s = kubernetes
  }

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  depends_on = [module.eks]
}