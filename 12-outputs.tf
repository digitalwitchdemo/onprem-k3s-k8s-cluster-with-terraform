# Private key saved locally so you can SSH into the instances
resource "local_sensitive_file" "ec2_private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/my-ec2-key.pem"
  file_permission = "0600"
}

# ---- k3s outputs ----
output "master_public_ip" {
  value = aws_instance.ec2_master_instance.public_ip
}

output "master_private_ip" {
  value = aws_instance.ec2_master_instance.private_ip
}

output "worker_public_ips" {
  value = aws_instance.ec2_instance_worker[*].public_ip
}

output "ssh_master" {
  value = "ssh -i my-ec2-key.pem ubuntu@${aws_instance.ec2_master_instance.public_ip}"
}

output "ssh_workers" {
  value = [for w in aws_instance.ec2_instance_worker : "ssh -i my-ec2-key.pem ubuntu@${w.public_ip}"]
}

output "master_node_token_command" {
  description = "Prints the master node token (run on the master)"
  value       = "sudo cat /var/lib/rancher/k3s/server/node-token"
}

output "kubeconfig_file" {
  description = "Kubeconfig downloaded from the master by scp, pointed at the master's public IP"
  value       = abspath("${path.module}/kubeconfig")
}

output "kubeconfig_command" {
  description = "Re-download the kubeconfig manually if needed"
  value       = "scp -i my-ec2-key.pem ubuntu@${aws_instance.ec2_master_instance.public_ip}:/home/ubuntu/kubeconfig kubeconfig"
}

# ---- S3 copies ----
output "s3_node_token" {
  value = "s3://${var.s3_bucket}/${aws_s3_object.node_token.key}"
}

output "s3_kubeconfig" {
  value = "s3://${var.s3_bucket}/${aws_s3_object.kubeconfig.key}"
}

output "s3_kubeconfig_download_command" {
  description = "Download the kubeconfig from S3 on any machine with AWS credentials"
  value       = "aws s3 cp s3://${var.s3_bucket}/${aws_s3_object.kubeconfig.key} kubeconfig"
}

# ---- Add-on outputs ----
output "load_balancer_ip" {
  description = "NGINX LoadBalancer IP (the master's public IP). Point your DNS A records here"
  # try() keeps plan/destroy working while the IP is still <pending>
  value = try(data.kubernetes_service_v1.nginx_ingress.status[0].load_balancer[0].ingress[0].ip, "pending")
}

output "argocd_url" {
  value = "https://${var.argocd_hostname}"
}

output "argocd_ingress_apply_command" {
  description = "Create the Argo CD Ingress manually (after the DNS A record points at load_balancer_ip)"
  value       = "kubectl apply -f manifests/argocd-ingress.yaml"
}

output "argocd_admin_username" {
  value = "admin"
}

output "argocd_initial_admin_password" {
  # try(): Argo CD's initial secret may be deleted after first login
  value     = try(data.kubernetes_secret_v1.argocd_initial_admin.data["password"], "deleted")
  sensitive = true
}
