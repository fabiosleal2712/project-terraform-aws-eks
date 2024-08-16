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
  security_group_id = var.security_group_id
}

module "eks" {
  source = "./modules/eks"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

module "rds" {
  source = "./modules/rds"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  security_group_id = var.security_group_id
  db_password = var.db_password
}


module "secrets_manager" {
  source = "./modules/secrets_manager"
  db_password = var.db_password
}

module "cdn" {
  source = "./modules/cdn"
  origin_domain_name = "example.com"
}