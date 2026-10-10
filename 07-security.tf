resource "aws_security_group" "sec_group" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "sec_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_443_ipv4" {
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_3000_ipv4" {
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---- Security group for k3s cluster traffic ----
resource "aws_security_group" "k3s" {
  name        = "k3s-cluster"
  description = "k3s API and node-to-node traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "k3s_sec_group"
  }
}

# kubectl access to the API server from outside
resource "aws_vpc_security_group_ingress_rule" "k3s_api" {
  security_group_id = aws_security_group.k3s.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 6443
  ip_protocol       = "tcp"
  to_port           = 6443
}

# All traffic between cluster nodes (kubelet 10250, flannel VXLAN 8472/udp, etc.)
resource "aws_vpc_security_group_ingress_rule" "k3s_self" {
  security_group_id            = aws_security_group.k3s.id
  referenced_security_group_id = aws_security_group.k3s.id
  ip_protocol                  = "-1"
}

# NodePort services
resource "aws_vpc_security_group_ingress_rule" "k3s_nodeports" {
  security_group_id = aws_security_group.k3s.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 30000
  ip_protocol       = "tcp"
  to_port           = 32767
}

resource "aws_vpc_security_group_egress_rule" "k3s_all_out" {
  security_group_id = aws_security_group.k3s.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
