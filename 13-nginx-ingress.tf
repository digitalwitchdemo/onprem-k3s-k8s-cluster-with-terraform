# ---- F5 NGINX Ingress Controller exposed on the master node's public IP ----
#
# k3s ships with ServiceLB, a built-in load balancer for "LoadBalancer" services.
# Labelling only the master with enablelb=true makes ServiceLB use just that node,
# so the LoadBalancer IP becomes the master's public IP (its --node-external-ip).

resource "kubernetes_labels" "master_enablelb" {
  api_version = "v1"
  kind        = "Node"

  metadata {
    name = aws_instance.ec2_master_instance.tags["Name"]
  }

  labels = {
    "svccontroller.k3s.cattle.io/enablelb" = "true"
  }
}

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "oci://ghcr.io/nginx/charts"
  chart            = "nginx-ingress"
  version          = "2.7.2"
  namespace        = "nginx-ingress"
  create_namespace = true

  values = [yamlencode({
    controller = {
      replicaCount = 1

      ingressClass = {
        name                = "nginx"
        create              = true
        setAsDefaultIngress = true
      }

      # Lets cert-manager issue certificates for VirtualServer resources too
      enableCertManager = true

      service = {
        type = "LoadBalancer"

        # The chart defaults to "Local", which makes ServiceLB report an IP only for a
        # node running BOTH the svclb pod (master only) and an NGINX pod (any node).
        # "Cluster" lets the master forward to NGINX wherever it runs, so the
        # LoadBalancer gets the master's public IP instead of staying <pending>.
        externalTrafficPolicy = "Cluster"
      }
    }
  })]

  depends_on = [
    kubernetes_labels.master_enablelb,
    aws_instance.ec2_instance_worker,
  ]
}

# The LoadBalancer service, read back to show the IP it was given
data "kubernetes_service_v1" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress-controller"
    namespace = helm_release.nginx_ingress.namespace
  }
}
