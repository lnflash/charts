resource "helm_release" "rtl" {
  name      = "rtl"
  chart     = "${path.module}/../../charts/rtl"
  namespace = kubernetes_namespace.bitcoin.metadata[0].name

  dependency_update = true

  wait    = false
  timeout = 900

  depends_on = [
    helm_release.lnd,
    helm_release.loop
  ]
}
