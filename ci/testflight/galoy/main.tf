variable "testflight_namespace" {}
variable "smoketest_kubeconfig" {}
variable "testflight_backups_creds" {}
variable "TWILIO_VERIFY_SERVICE_ID" {}
variable "TWILIO_ACCOUNT_SID" {}
variable "TWILIO_AUTH_TOKEN" {}
variable "IBEX_PASSWORD" {}

locals {
  cluster_name     = "galoy-staging-cluster"
  cluster_location = "us-east1"
  gcp_project      = "galoy-staging"

  smoketest_namespace  = "flash-staging-smoketest"
  # bitcoin_namespace    = "galoy-staging-bitcoin"
  testflight_namespace = var.testflight_namespace
  smoketest_kubeconfig = var.smoketest_kubeconfig
  backups_sa_creds     = var.testflight_backups_creds

  testflight_api_host = "galoy-oathkeeper-proxy.${local.testflight_namespace}.svc.cluster.local"
  kratos_admin_host   = "galoy-kratos-admin.${local.testflight_namespace}.svc.cluster.local"
  kratos_pg_host      = "postgresql.${local.testflight_namespace}.svc.cluster.local"

  postgres_database = "price-history"
  postgres_username = "price-history"
  postgres_password = "price-history"
}

# data "kubernetes_secret" "network" {
#   metadata {
#     name      = "network"
#     namespace = local.bitcoin_namespace
#   }
# }

# resource "kubernetes_secret" "network" {
#   metadata {
#     name      = "network"
#     namespace = kubernetes_namespace.testflight.metadata[0].name
#   }

#   data = data.kubernetes_secret.network.data
# }

resource "kubernetes_secret" "gcs_sa_key" {
  metadata {
    name      = "gcs-sa-key"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }

  data = {
    "gcs-sa-key.json" : local.backups_sa_creds
  }
}

resource "kubernetes_secret" "geetest_key" {
  metadata {
    name      = "geetest-key"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }

  data = {
    key = "geetest_key"
    id  = "geetest_id"
  }
}

resource "kubernetes_secret" "dropbox_access_token" {
  metadata {
    name      = "dropbox-access-token"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }

  data = {
    token = "dummy"
  }
}

resource "kubernetes_secret" "mongodb_creds" {
  metadata {
    name      = "galoy-mongodb"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }

  data = {
    "mongodb-password" : "password"
    "mongodb-passwords" : "password"
    "mongodb-root-password" : "password"
    "mongodb-replica-set-key" : "replica"
  }
}

resource "kubernetes_secret" "mongodb_connection_string" {
  metadata {
    name      = "galoy-mongodb-connection-string"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }

  data = {
    "mongodb-con" : "mongodb://testGaloy:password@galoy-mongodb-0.galoy-mongodb-headless,galoy-mongodb-1.galoy-mongodb-headless,galoy-mongodb-2.galoy-mongodb-headless/galoy"
  }
}

resource "kubernetes_secret" "twilio_secret" {
  metadata {
    name      = "twilio-secret"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }

  data = {
    TWILIO_VERIFY_SERVICE_ID = var.TWILIO_VERIFY_SERVICE_ID
    TWILIO_ACCOUNT_SID       = var.TWILIO_ACCOUNT_SID
    TWILIO_AUTH_TOKEN        = var.TWILIO_AUTH_TOKEN
  }
}

# data "kubernetes_secret" "bitcoin_rpcpassword" {
#   metadata {
#     name      = "bitcoind-rpcpassword"
#     namespace = local.bitcoin_namespace
#   }
# }

# resource "kubernetes_secret" "bitcoinrpc_password" {
#   metadata {
#     name      = "bitcoind-rpcpassword"
#     namespace = kubernetes_namespace.testflight.metadata[0].name
#   }

#   data = data.kubernetes_secret.bitcoin_rpcpassword.data
# }

# data "kubernetes_secret" "lnd2_pubkey" {
#   metadata {
#     name      = "lnd2-pubkey"
#     namespace = local.bitcoin_namespace
#   }
# }

# resource "kubernetes_secret" "lnd2_pubkey" {
#   metadata {
#     name      = "lnd2-pubkey"
#     namespace = kubernetes_namespace.testflight.metadata[0].name
#   }

#   data = data.kubernetes_secret.lnd2_pubkey.data
# }

# data "kubernetes_secret" "lnd1_pubkey" {
#   metadata {
#     name      = "lnd1-pubkey"
#     namespace = local.bitcoin_namespace
#   }
# }

# resource "kubernetes_secret" "lnd1_pubkey" {
#   metadata {
#     name      = "lnd1-pubkey"
#     namespace = kubernetes_namespace.testflight.metadata[0].name
#   }

#   data = data.kubernetes_secret.lnd1_pubkey.data
# }

# data "kubernetes_secret" "lnd2_credentials" {
#   metadata {
#     name      = "lnd2-credentials"
#     namespace = local.bitcoin_namespace
#   }
# }

# resource "kubernetes_secret" "lnd2_credentials" {
#   metadata {
#     name      = "lnd2-credentials"
#     namespace = kubernetes_namespace.testflight.metadata[0].name
#   }

#   data = data.kubernetes_secret.lnd2_credentials.data
# }

# data "kubernetes_secret" "lnd1_credentials" {
#   metadata {
#     name      = "lnd1-credentials"
#     namespace = local.bitcoin_namespace
#   }
# }

# resource "kubernetes_secret" "lnd1_credentials" {
#   metadata {
#     name      = "lnd1-credentials"
#     namespace = kubernetes_namespace.testflight.metadata[0].name
#   }

#   data = data.kubernetes_secret.lnd1_credentials.data
# }

# data "kubernetes_secret" "loop1_credentials" {
#   metadata {
#     name      = "loop1-credentials"
#     namespace = local.bitcoin_namespace
#   }
# }

# resource "kubernetes_secret" "loop1_credentials" {
#   metadata {
#     name      = "loop1-credentials"
#     namespace = kubernetes_namespace.testflight.metadata[0].name
#   }

#   data = data.kubernetes_secret.loop1_credentials.data
# }

# data "kubernetes_secret" "loop2_credentials" {
#   metadata {
#     name      = "loop2-credentials"
#     namespace = local.bitcoin_namespace
#   }
# }

# resource "kubernetes_secret" "loop2_credentials" {
#   metadata {
#     name      = "loop2-credentials"
#     namespace = kubernetes_namespace.testflight.metadata[0].name
#   }

#   data = data.kubernetes_secret.loop2_credentials.data
# }

# data "kubernetes_secret" "bria_credentials" {
#   metadata {
#     name      = "galoy-bria-creds"
#     namespace = local.bitcoin_namespace
#   }
# }

# resource "kubernetes_secret" "bria_credentials" {
#   metadata {
#     name      = "bria-api-key"
#     namespace = kubernetes_namespace.testflight.metadata[0].name
#   }

#   data = data.kubernetes_secret.bria_credentials.data
# }

resource "kubernetes_namespace" "testflight" {
  metadata {
    name = local.testflight_namespace
  }
}

resource "kubernetes_secret" "smoketest" {
  metadata {
    name      = local.testflight_namespace
    namespace = local.smoketest_namespace
  }
  data = {
    galoy_endpoint         = local.testflight_api_host
    galoy_port             = 4455
    price_history_endpoint = "galoy-price-history.${local.testflight_namespace}.svc.cluster.local"
    price_history_port     = 50052
  }
}

resource "kubernetes_secret" "price_history_postgres_creds" {
  metadata {
    name      = "galoy-price-history-postgres-creds"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }

  data = {
    username = local.postgres_username
    password = local.postgres_password
    database = local.postgres_database
  }
}

resource "random_password" "redis" {
  length  = 20
  special = false
}

resource "kubernetes_secret" "redis_password" {
  metadata {
    name      = "galoy-redis"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }

  data = {
    "redis-password" : random_password.redis.result
  }
}

resource "jose_keyset" "oathkeeper" {}

resource "kubernetes_secret" "oathkeeper" {
  metadata {
    name      = "galoy-oathkeeper"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }

  data = {
    "mutator.id_token.jwks.json" = jsonencode({
      keys = [jsondecode(jose_keyset.oathkeeper.private_key)]
    })
  }
}

resource "random_password" "kratos_master_user_password" {
  length  = 32
  special = false
}

resource "random_password" "kratos_callback_api_key" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "kratos_master_user_password" {
  metadata {
    name      = "kratos-secret"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }

  data = {
    "master_user_password" = random_password.kratos_master_user_password.result
    "callback_api_key"     = random_password.kratos_callback_api_key.result
  }
}

resource "kubernetes_secret" "svix_secret" {
  metadata {
    name      = "svix-secret"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }
  data = {
    "svix-secret" = "dummy"
  }
}

resource "kubernetes_secret" "proxy_check_api_key" {
  metadata {
    name      = "proxy-check-api-key"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }
  data = {
    "api-key" = "dummy"
  }
}

resource "kubernetes_secret" "ibex_auth" {
  metadata {
    name      = "ibex-auth"
    namespace = kubernetes_namespace.testflight.metadata[0].name
  }

  data = {
    "api-password" : var.IBEX_PASSWORD 
    "webhook-secret" : "not-so-secret"
  }
}

resource "helm_release" "postgresql" {
  name       = "postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "11.9.13"
  namespace  = kubernetes_namespace.testflight.metadata[0].name

  values = [
    file("${path.module}/postgresql-values.yml")
  ]
}

resource "helm_release" "flash" {
  name       = "flash"
  chart      = "${path.module}/chart"
  repository = "https://galoymoney.github.io/charts/"
  namespace  = kubernetes_namespace.testflight.metadata[0].name

  values = [
    templatefile("${path.module}/testflight-values.yml.tmpl", {
      kratos_pg_host : local.kratos_pg_host,
      kratos_callback_api_key : random_password.kratos_callback_api_key.result
    }),
    file("${path.module}/testflight-values.yml")
  ]

  depends_on = [
    # kubernetes_secret.bitcoinrpc_password,
    # kubernetes_secret.lnd1_credentials,
    # kubernetes_secret.loop1_credentials,
    # kubernetes_secret.lnd1_pubkey,
    # kubernetes_secret.lnd2_credentials,
    # kubernetes_secret.loop2_credentials,
    # kubernetes_secret.lnd2_pubkey,
    kubernetes_secret.price_history_postgres_creds,
    kubernetes_secret.ibex_auth,
    helm_release.postgresql
  ]

  dependency_update = true
}

data "google_container_cluster" "primary" {
  project  = local.gcp_project
  name     = local.cluster_name
  location = local.cluster_location
}

data "google_client_config" "default" {
  provider = google-beta
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.private_cluster_config.0.private_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}

provider "kubernetes-alpha" {
  host                   = "https://${data.google_container_cluster.primary.private_cluster_config.0.private_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.primary.private_cluster_config.0.private_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  }
}

terraform {
  required_providers {
    jose = {
      source  = "bluemill/jose"
      version = "1.0.0"
    }
  }
}
