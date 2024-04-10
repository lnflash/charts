
variable "HONEYCOMB_API_KEY" {
  description = "The api key to write open-telemetry data to Honeycomb"
  type        = string
  sensitive   = true
}

resource "kubernetes_namespace" "otel" {
  metadata {
    name = "otel"
  }
}

resource "helm_release" "collector" {
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = "0.68.1"
  name       = "opentelemetry-collector"
  namespace  = kubernetes_namespace.otel.metadata[0].name

  values = [
    # file("${path.module}/staging-values.yaml"),
    # {
    #   extraEnvs = [
    #     {
    #       name  = "HONEYCOMB_API_KEY"
    #       value = var.HONEYCOMB_API_KEY
    #     }
    #   ]
    # }

    # This approach treats MY_POD_IP as a template parameter
    templatefile("${path.module}/staging-values.yaml", {
      HONEYCOMB_API_KEY = var.HONEYCOMB_API_KEY
    }) 
  ]
#   {
#     extraEnvs = [
#       {
#         name  = "HONEYCOMB_API_KEY"
#         value = var.HONEYCOMB_API_KEY}  
#       }
#     ]
#   }
}