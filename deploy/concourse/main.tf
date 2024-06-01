variable "CONCOURSE_GITHUB_CLIENT_ID" {
  description = "The github id for concourse Oauth application"
  type        = string
}

variable "CONCOURSE_GITHUB_CLIENT_SECRET" {
  description = "The secret for Oauth authentication to Github"
  type        = string
  sensitive   = true
}

resource "kubernetes_namespace" "concourse" {
  metadata {
    name = "concourse"
  }
}

resource "kubernetes_secret" "gh_oauth" {
  metadata {
    name      = "github-concourse-oauth"
    namespace = kubernetes_namespace.concourse.metadata[0].name
  }

  data = {
    "CONCOURSE_GITHUB_CLIENT_ID" : var.CONCOURSE_GITHUB_CLIENT_ID 
    "CONCOURSE_GITHUB_CLIENT_SECRET" : var.CONCOURSE_GITHUB_CLIENT_SECRET 
  }
}

resource "helm_release" "concourse" {
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "concourse"
  version    = "4.0.1"
  name       = "bitnami-concourse"
  namespace  = kubernetes_namespace.concourse.metadata[0].name

  values = [
    file("./values.yml")
  ]

  depends_on = [
    kubernetes_secret.gh_oauth
  ]
}