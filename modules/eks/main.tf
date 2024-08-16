module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.23.0"
  cluster_name    = "my-cluster"
  cluster_version = "1.30"
  subnet_ids      = ["subnet-0c1a0b6147c3629da", "subnet-07d9c136e6c94c03d"]
  vpc_id          = "vpc-09c6102458be2706e"
  
  self_managed_node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 5
      min_capacity     = 1
      instance_type    = "t3.medium"
    }
  }
}