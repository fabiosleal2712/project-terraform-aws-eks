resource "null_resource" "prometheus" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl apply --validate=false -f ${path.module}/prometheus-deployment.yaml
    EOT
  }
}


#provider "kubernetes" {
#  config_path = "~/.kube/config"
#}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
      configuration_aliases = [
        kubernetes.k8s,
      ]
    }
  }
}