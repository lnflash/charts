variable "name_prefix" {}

locals {
  smoketest_namespace = "${var.name_prefix}-smoketest"
  galoy_namespace     = "${var.name_prefix}-galoy"
}

resource "kubernetes_secret" "lnd_credentials" {
  metadata {
    name      = "lnd-credentials"
    namespace = local.galoy_namespace
  }

  data = {
    readonly_macaroon_base64 = base64encode("dummy")
    tls_base64               = base64encode("dummy")
  }
}

resource "kubernetes_secret" "nostr_private_key" {
  metadata {
    name      = "galoy-nostr-private-key"
    namespace = local.galoy_namespace
  }

  data = {
    key = "bb159f7aaafa75a7d4470307c9d6ea18409d4f082b41abcf6346aaae5b2b3b10"
  }
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

  depends_on = [
    kubernetes_secret.lnd_credentials,
    kubernetes_secret.nostr_private_key
  ]

  dependency_update = true
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
