provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"
  cidr_block = var.vpc_cidr
}

module "ec2" {
  source = "./modules/ec2"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group" "main" {
  vpc_id = module.vpc.vpc_id
  description = "Main security group"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
module "eks" {
  source = "./modules/eks"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
}

provider "kubernetes" {
  config_path = "~/.kube/kubeconfig"
}

module "rds" {
  source = "./modules/rds"
  vpc_id = module.vpc.vpc_id  
  subnet_ids = module.vpc.private_subnets
  security_group_id = aws_security_group.main.id  
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
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

module "grafana" {
  source = "./modules/grafana"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}