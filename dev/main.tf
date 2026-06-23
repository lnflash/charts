variable "bitcoin_network" {}
variable "name_prefix" {}


locals {
  bitcoin_network = var.bitcoin_network
  name_prefix     = var.name_prefix
}

module "galoy_deps" {
  source             = "./galoy-deps"
  cloudflare_api_key = var.cloudflare_api_key
  cloudflare_email   = var.cloudflare_email
  name_prefix        = local.name_prefix
}

module "infra_services" {
  source = "./infra-services"

  name_prefix = local.name_prefix
}

module "galoy" {
  source = "./galoy"

  bitcoin_network          = local.bitcoin_network
  name_prefix              = local.name_prefix
  TWILIO_VERIFY_SERVICE_ID = var.TWILIO_VERIFY_SERVICE_ID
  TWILIO_ACCOUNT_SID       = var.TWILIO_ACCOUNT_SID
  TWILIO_AUTH_TOKEN        = var.TWILIO_AUTH_TOKEN
  IBEX_PASSWORD            = var.IBEX_PASSWORD
  depends_on = [
    module.galoy_deps,
    module.infra_services
  ]
}

module "flash_pay" {
  source = "./flash-pay"

  name_prefix = local.name_prefix

  depends_on = [
    module.galoy,
    module.infra_services
  ]
}

module "nostr" {
  source = "./nostr"

  name_prefix = local.name_prefix

  depends_on = [
    module.galoy,
    module.infra_services
  ]
}

module "smoketest" {
  source = "./smoketest"

  name_prefix = local.name_prefix

  depends_on = [
    module.infra_services
  ]
}

provider "kubernetes" {
  experiments {
    manifest_resource = true
  }
}
