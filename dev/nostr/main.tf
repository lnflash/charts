variable "name_prefix" {}

locals {
  galoy_namespace     = "${var.name_prefix}-galoy"
  nostr_namespace     = "${var.name_prefix}-nostr"
  smoketest_namespace = "${var.name_prefix}-smoketest"
}

resource "kubernetes_namespace" "nostr" {
  metadata {
    name = local.nostr_namespace
  }
}

resource "helm_release" "nostr_multiplexer" {
  name      = "multiplexer-release"
  chart     = "${path.module}/../../charts/nostr-multiplexer"
  namespace = kubernetes_namespace.nostr.metadata[0].name

  set = [
    {
      name  = "graphqlUrl"
      value = "http://flash-oathkeeper-proxy.${local.galoy_namespace}.svc.cluster.local:4455/graphql"
    },
    {
      name  = "ingress.hosts[0]"
      value = "localhost"
    }
  ]

  wait    = false
  timeout = 300
}

resource "helm_release" "strfry" {
  name      = "strfry-release"
  chart     = "${path.module}/../../charts/strfry"
  namespace = kubernetes_namespace.nostr.metadata[0].name

  set = [
    {
      name  = "ingress.hosts[0]"
      value = "relay.localhost"
    },
    {
      name  = "persistence.size"
      value = "1Gi"
    }
  ]

  wait    = false
  timeout = 300
}

resource "kubernetes_secret" "nostr_smoketest" {
  metadata {
    name      = "nostr-smoketest"
    namespace = local.smoketest_namespace
  }

  data = {
    nostr_multiplexer_host = "multiplexer-release-nostr-multiplexer.${local.nostr_namespace}.svc.cluster.local"
    nostr_multiplexer_port = 4000
    strfry_host            = "strfry-release-strfry.${local.nostr_namespace}.svc.cluster.local"
    strfry_port            = 7777
  }
}
