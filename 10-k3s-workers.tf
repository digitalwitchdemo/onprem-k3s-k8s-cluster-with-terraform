# ---- Worker nodes ----
# One public subnet per availability zone. Workers take turns:
# worker-node-01 → AZ 1, worker-node-02 → AZ 2, worker-node-03 → AZ 1, ...
locals {
  worker_subnets = [
    aws_subnet.public_subnet_01.id, # Availability Zone 1
    aws_subnet.public_subnet_02.id, # Availability Zone 2
  ]
}

resource "aws_instance" "ec2_instance_worker" {
  count = var.worker_count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  subnet_id              = element(local.worker_subnets, count.index)
  key_name               = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids = [aws_security_group.sec_group.id, aws_security_group.k3s.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = format("worker-node-%02d", count.index + 1)
  }

  # Keep the network path open for as long as the workers exist (see 09-k3s-master.tf)
  depends_on = [
    aws_route.route,
    aws_route_table_association.route_assocate_01,
    aws_route_table_association.route_assocate_02,
    aws_vpc_security_group_ingress_rule.allow_ssh_ipv4,
    aws_vpc_security_group_ingress_rule.k3s_self,
    aws_vpc_security_group_egress_rule.allow_all_traffic_ipv4,
    aws_vpc_security_group_egress_rule.k3s_all_out,
  ]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh_key.private_key_pem
  }

  # Step 1: copy the install script to the worker
  provisioner "file" {
    source      = "${path.module}/scripts/k3s-worker.sh"
    destination = "/tmp/k3s-worker.sh"
  }

  # Step 2: join the master, injecting the master token read from S3.
  # Workers reach the master on its private IP inside the network.
  provisioner "remote-exec" {
    inline = [
      "sudo bash /tmp/k3s-worker.sh ${aws_instance.ec2_master_instance.private_ip} ${trimspace(data.aws_s3_object.node_token.body)} ${self.public_ip} ${self.tags["Name"]}"
    ]
  }
}
