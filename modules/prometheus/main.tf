resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "monitoring"

  set {
    name  = "service.type"
    value = "ClusterIP"
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/kubeconfig"
  }
}