variable "name_prefix" {}

locals {
  smoketest_namespace = "${var.name_prefix}-smoketest"
  galoy_namespace     = "${var.name_prefix}-galoy"
}

resource "helm_release" "flash_pay" {
  name      = "flash-pay"
  chart     = "${path.module}/../../charts/flash-pay"
  namespace = local.galoy_namespace

  values = [
    templatefile("${path.module}/values.yml.tmpl", {
      galoy_namespace = local.galoy_namespace
    })
  ]

  dependency_update = false
  wait              = false
  timeout           = 300
}

resource "kubernetes_secret" "flash_pay_smoketest" {
  metadata {
    name      = "galoy-pay-smoketest"
    namespace = local.smoketest_namespace
  }

  data = {
    galoy_pay_endpoints  = jsonencode(["flash-pay.${local.galoy_namespace}.svc.cluster.local"])
    galoy_pay_port       = 80
    lnurl_check_disabled = "true"
  }
}
