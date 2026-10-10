# ---- Store the node-token and kubeconfig in S3 ----
# Uploaded from the files scp downloaded above. Re-uploaded whenever the master is rebuilt.
resource "aws_s3_object" "node_token" {
  bucket                 = var.s3_bucket
  key                    = "k3s/node-token"
  source                 = "${path.module}/node-token"
  content_type           = "text/plain"
  server_side_encryption = "AES256"

  depends_on = [aws_instance.ec2_master_instance]

  lifecycle {
    replace_triggered_by = [aws_instance.ec2_master_instance]
  }
}

resource "aws_s3_object" "kubeconfig" {
  bucket                 = var.s3_bucket
  key                    = "k3s/kubeconfig"
  source                 = "${path.module}/kubeconfig"
  content_type           = "text/plain"
  server_side_encryption = "AES256"

  depends_on = [aws_instance.ec2_master_instance]

  lifecycle {
    replace_triggered_by = [aws_instance.ec2_master_instance]
  }
}

# The token read back from S3 so it can be injected into the workers
# (works from any machine, even one without the local ./node-token file)
data "aws_s3_object" "node_token" {
  bucket     = var.s3_bucket
  key        = aws_s3_object.node_token.key
  depends_on = [aws_s3_object.node_token]
}
