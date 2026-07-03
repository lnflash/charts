variable "name_prefix" {}
variable "bitcoin_network" {}
variable "TWILIO_VERIFY_SERVICE_ID" {}
variable "TWILIO_ACCOUNT_SID" {}
variable "TWILIO_AUTH_TOKEN" {}
variable "IBEX_PASSWORD" {}

locals {
  smoketest_namespace       = "${var.name_prefix}-smoketest"
  galoy_namespace           = "${var.name_prefix}-galoy"
  galoy_oathkeeper_proxy    = "flash-oathkeeper-proxy.${local.galoy_namespace}.svc.cluster.local"
  price_history_service     = "flash-price-history.${local.galoy_namespace}.svc.cluster.local"
  kratos_pg_host            = "postgresql.${local.galoy_namespace}.svc.cluster.local"
  nostr_zap_receipts_key    = "bb159f7aaafa75a7d4470307c9d6ea18409d4f082b41abcf6346aaae5b2b3b10"
  dummy_lnd_pubkey          = "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"
  dummy_base64_secret_value = base64encode("dummy")
}

resource "kubernetes_namespace" "galoy" {
  metadata {
    name = local.galoy_namespace
  }
}

resource "helm_release" "postgresql" {
  name       = "postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "15.5.38"
  namespace  = kubernetes_namespace.galoy.metadata[0].name

  values = [
    file("${path.module}/postgresql-values.yml")
  ]

  wait    = false
  timeout = 300
}

resource "random_password" "kratos_master_user_password" {
  length  = 32
  special = false
}

resource "random_password" "kratos_callback_api_key" {
  length  = 32
  special = false
}

resource "random_password" "admin_api_key" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "kratos_master_user_password" {
  metadata {
    name      = "kratos-secret"
    namespace = kubernetes_namespace.galoy.metadata[0].name
  }

  data = {
    "master_user_password" = random_password.kratos_master_user_password.result
    "callback_api_key"     = random_password.kratos_callback_api_key.result
  }
}

resource "kubernetes_secret" "oathkeeper" {
  metadata {
    name      = "flash-oathkeeper"
    namespace = kubernetes_namespace.galoy.metadata[0].name
  }

  data = {
    "mutator.id_token.jwks.json" = file("${path.module}/oathkeeper_mutator_id_token_jwks.json")
  }
}

resource "kubernetes_secret" "ibex_auth" {
  metadata {
    name      = "ibex-auth"
    namespace = kubernetes_namespace.galoy.metadata[0].name
  }

  data = {
    "api-password"   = var.IBEX_PASSWORD
    "api-email"      = "dev@example.com"
    "client-id"      = "dev-client-id"
    "client-secret"  = var.IBEX_PASSWORD
    "webhook-secret" = "not-so-secret"
  }
}

resource "kubernetes_secret" "admin_api" {
  metadata {
    name      = "admin-api"
    namespace = kubernetes_namespace.galoy.metadata[0].name
  }

  data = {
    "api-key" = random_password.admin_api_key.result
  }
}

resource "kubernetes_secret" "flash_nostr_keys" {
  metadata {
    name      = "flash-nostr-keys"
    namespace = kubernetes_namespace.galoy.metadata[0].name
  }

  data = {
    zapReceipts = local.nostr_zap_receipts_key
  }
}

resource "helm_release" "galoy" {
  name      = "flash"
  chart     = "${path.module}/../../charts/flash"
  namespace = kubernetes_namespace.galoy.metadata[0].name

  values = [
    templatefile("${path.module}/galoy-values.yml.tmpl", {
      kratos_pg_host            = local.kratos_pg_host,
      kratos_callback_api_key   = random_password.kratos_callback_api_key.result,
      dummy_lnd_pubkey          = local.dummy_lnd_pubkey,
      dummy_base64_secret_value = local.dummy_base64_secret_value,
      twilio_verify_service_id  = var.TWILIO_VERIFY_SERVICE_ID,
      twilio_account_sid        = var.TWILIO_ACCOUNT_SID,
      twilio_auth_token         = var.TWILIO_AUTH_TOKEN,
      ibex_listener_host        = "http://ibex-webhook.${local.galoy_namespace}.svc.cluster.local:4008"
    }),
    file("${path.module}/galoy-${var.bitcoin_network}-values.yml")
  ]

  depends_on = [
    helm_release.postgresql,
    kubernetes_secret.admin_api,
    kubernetes_secret.flash_nostr_keys,
    kubernetes_secret.ibex_auth,
    kubernetes_secret.kratos_master_user_password,
    kubernetes_secret.oathkeeper
  ]

  dependency_update = false
  wait              = false
  timeout           = 900
}

resource "kubernetes_secret" "smoketest" {
  metadata {
    name      = "galoy-smoketest"
    namespace = local.smoketest_namespace
  }

  data = {
    galoy_endpoint         = local.galoy_oathkeeper_proxy
    galoy_port             = 4455
    price_history_endpoint = local.price_history_service
    price_history_port     = 50052
  }
}
