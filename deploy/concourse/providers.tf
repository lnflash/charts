provider "kubernetes" {
  config_path    = "~/.kube/config"  # Path to your kubeconfig file
  config_context = "do-nyc1-flashcluster"  # Name of the Kubernetes context to use
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "do-nyc1-flashcluster"  # Name of the Kubernetes context to use
 }
}