resource "null_resource" "prometheus" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl apply --validate=false -f ${path.module}/prometheus-deployment.yaml
    EOT
  }
}
provider "kubernetes" {
  config_path = "~/.kube/config"
}