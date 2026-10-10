# ---- cert-manager: issues and renews TLS certificates from Let's Encrypt ----
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.21.2"
  namespace        = "cert-manager"
  create_namespace = true

  values = [yamlencode({
    crds = {
      enabled = true
    }
  })]

  depends_on = [aws_instance.ec2_instance_worker]
}

# letsencrypt-staging and letsencrypt-prod ClusterIssuers, from the local chart in ./charts
resource "helm_release" "cluster_issuer" {
  name      = "cluster-issuer"
  chart     = "${path.module}/charts/cluster-issuer"
  namespace = helm_release.cert_manager.namespace

  values = [yamlencode({
    email            = var.letsencrypt_email
    ingressClassName = "nginx"
  })]

  depends_on = [helm_release.cert_manager]
}
