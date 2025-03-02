data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.23.0"
  cluster_name    = "my-new-cluster"
  cluster_version = "1.30"
  subnet_ids      = var.subnet_ids  // Usando a variável subnet_ids
  vpc_id          = var.vpc_id
  
  self_managed_node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 5
      min_capacity     = 1
      instance_type    = "t3.medium"
    }
  }
}

resource "aws_eks_cluster" "this" {
  name     = "my-new-cluster-unique-name"
  role_arn = aws_iam_role.this.arn
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids  // Use a variável aqui
    endpoint_public_access  = true
    endpoint_private_access = true
  }
}

resource "aws_iam_role" "this" {
  name = "eks_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

// Remover a declaração duplicada do recurso aws_iam_role_policy.eks_policy