variable "bitcoin_network" {}
variable "name_prefix" {}

locals {
  bitcoin_network = var.bitcoin_network
  name_prefix     = var.name_prefix
}

module "galoy_deps" {
  source = "./galoy-deps"

  name_prefix = local.name_prefix
}

module "infra_services" {
  source = "git::https://github.com/GaloyMoney/galoy-infra.git//modules/smoketest/gcp?ref=13b2ef9"

  name_prefix      = local.name_prefix
  cluster_endpoint = "https://172.16.0.2"
  cluster_ca_cert  = <<EOT
-----BEGIN CERTIFICATE-----
MIIELTCCApWgAwIBAgIRAJOQ0jfwX5XRX/52h/IdFPMwDQYJKoZIhvcNAQELBQAw
LzEtMCsGA1UEAxMkZmNhYzIzNmYtYjNhZS00Yzg1LThiMmItNmMwNjBjM2FjYmU5
MCAXDTIzMDgyNzEzMjc1NVoYDzIwNTMwODE5MTQyNzU1WjAvMS0wKwYDVQQDEyRm
Y2FjMjM2Zi1iM2FlLTRjODUtOGIyYi02YzA2MGMzYWNiZTkwggGiMA0GCSqGSIb3
DQEBAQUAA4IBjwAwggGKAoIBgQDQLoyiI0wa8XHHmR1UvcbsZu3J5ZmiI7oFutx1
aTa4M0upBQ/uFNfTMpepF48r3rQK+ZG1VLNwGiJ62s1hBjXCVbJLBvIEGpjjlso0
IebG5bKdJNVrNT4ircd1qeBUHXOzmuOAxgCBBd+sEbbqYQnUTquQL1kwXxb67pWG
ET72IJPzEZxq3ByGU9kGsQSJNBzReAQvHQXT7J5u4P1pcYN1o4vrpwfbhh7oYips
EyxFqCBcsW+0lDE5ZhiRncHRqJtE0Nfz0y/Lcuq4miwrB77ff1aSc31Dw7k6MhM+
YVWXL1w0fbK2O7hXNfvu++SZizAU3gNYgKr5gDQnsNG20FCj3aocOcEDha6x0lZs
5drCOqN6GRwtGNZrYhLQBGUu5tnG4EgDGF/K1elkiq+xdSbR+TK9ddDKR7fBiimy
apDXOz/GEnkwXvEwKslfppasKGbaOgDQwudHMWVIHd7RQzoeKqgnhfkmZ9iXqMHD
4ufgNO6P6oEe0LmFRHrf1zuiecUCAwEAAaNCMEAwDgYDVR0PAQH/BAQDAgIEMA8G
A1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFNQf00Ha7vogkhi/6Iunhq1qwMCBMA0G
CSqGSIb3DQEBCwUAA4IBgQDFXHqUfm5p5/0VBKXePtmED9s4kJmQLMEDsd7pAf1y
hn7vjB7EhOdw0JHAWgIIgVQaB2Uzr0k1jR0Oe/I7l+iNnPd27A/p7m5K9qC+DKT9
RgUBnFkdr8Vgrbhho7SUzlRFCEeA2ROkfbq+r8trtnKfPq6hJmDFD6sTxkYJbY1o
2v0H0inLA+4qqwJrc+76FvxgfJyBgehPkhVW9kmuO85snzfr0Z3L84dKon+MeuQ2
DMj6aV388052iKIVyaj6rD+E3pDnGrLQVC6qxEGf5vStJKbgAiE5mZ+Jtbtuat2t
guzTrZ5RUqb+KHbyFOI5PzyPPaJrt3ShxvuQ0h7wC7scpGTtkEUaZc/EuODS38bb
2oqZsQDBtcbPmX1LQnoEFkqg3201cb2NbsQnZl9+gSE/WWvtzTmTMKIf+2vForI/
E5uQ9oav+GMqOoQ8lt4C7OzLgfE50MnUNKYzsGDj3MdUyQzE+vEe1y9GZnheAD4H
H60Yt7BjENZPYFEefuy0rVs=
-----END CERTIFICATE-----
EOT
}

module "kafka_connect" {
  source = "./kafka-connect"

  name_prefix = local.name_prefix

  depends_on = [
    module.galoy_deps,
    module.infra_services
  ]
}

module "bitcoin" {
  source = "./bitcoin"

  bitcoin_network = local.bitcoin_network
  name_prefix     = local.name_prefix

  depends_on = [
    module.galoy_deps
  ]
}

module "galoy" {
  source = "./galoy"

  bitcoin_network = local.bitcoin_network
  name_prefix     = local.name_prefix

  depends_on = [
    module.bitcoin
  ]
}

module "monitoring" {
  source = "./monitoring"

  name_prefix = local.name_prefix
}

module "addons" {
  source = "./addons"

  name_prefix = local.name_prefix

  depends_on = [
    module.galoy
  ]
}

module "smoketest" {
  source = "./smoketest"

  name_prefix = local.name_prefix
}

provider "kubernetes" {
  experiments {
    manifest_resource = true
  }
}
