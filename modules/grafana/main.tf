resource "null_resource" "grafana" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl apply --validate=false -f ${path.module}/grafana-deployment.yaml
    EOT
  }
}

#provider "kubernetes" {
#  config_path = "~/.kube/config"
#}



terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}