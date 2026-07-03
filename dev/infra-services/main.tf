variable "name_prefix" {}

locals {
  name_prefix            = var.name_prefix
  galoy_namespace        = "${local.name_prefix}-galoy"
  smoketest_namespace    = "${local.name_prefix}-smoketest"
  smoketest_name         = "smoketest"
  smoketest_cronjob      = false
  smoketest_cronjob_name = "${local.smoketest_name}-cronjob"
}

resource "kubernetes_namespace" "smoketest" {
  metadata {
    name = local.smoketest_namespace
  }
}

resource "kubernetes_role" "smoketest" {
  metadata {
    name      = local.smoketest_name
    namespace = kubernetes_namespace.smoketest.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_service_account" "smoketest" {
  metadata {
    name      = local.smoketest_name
    namespace = kubernetes_namespace.smoketest.metadata[0].name
  }
}

resource "kubernetes_secret" "smoketest_token" {
  metadata {
    name      = "${local.smoketest_name}-token"
    namespace = kubernetes_namespace.smoketest.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.smoketest.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_role_binding" "smoketest" {
  metadata {
    name      = local.smoketest_name
    namespace = kubernetes_namespace.smoketest.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.smoketest.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = local.smoketest_name
    namespace = kubernetes_role.smoketest.metadata[0].namespace
  }
}
