output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ec2_instance_ids" {
  value = module.ec2.instance_ids
}

output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "rds_endpoint" {
  value = module.rds.endpoint
}