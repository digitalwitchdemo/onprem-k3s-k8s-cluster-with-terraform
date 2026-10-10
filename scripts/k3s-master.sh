#!/bin/bash
# k3s MASTER node installation
# Usage: sudo bash k3s-master.sh <MASTER_PUBLIC_IP> <NODE_NAME>
#  1. installs k3s server with Traefik disabled, using the master's public IP
#  2. copies the master node token to /home/ubuntu/node-token so it can be fetched with scp
#  3. copies the kubeconfig to /home/ubuntu/kubeconfig so it can be fetched with scp
set -euo pipefail

MASTER_PUBLIC_IP="$1"
NODE_NAME="$2"

echo "==> Setting hostname to $NODE_NAME"
hostnamectl set-hostname "$NODE_NAME"

echo "==> Installing k3s server (public IP: $MASTER_PUBLIC_IP)"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --node-name $NODE_NAME --tls-san $MASTER_PUBLIC_IP --node-external-ip $MASTER_PUBLIC_IP --write-kubeconfig-mode 644" sh -

echo "==> Waiting for the master node token"
until [ -s /var/lib/rancher/k3s/server/node-token ]; do sleep 5; done

# The original file is readable by root only, so make a copy the ubuntu user can scp
cp /var/lib/rancher/k3s/server/node-token /home/ubuntu/node-token
chown ubuntu:ubuntu /home/ubuntu/node-token
chmod 600 /home/ubuntu/node-token

# Kubeconfig for remote access: k3s writes it pointing at 127.0.0.1,
# so make a copy that points at the master's public IP instead
sed "s/127.0.0.1/$MASTER_PUBLIC_IP/" /etc/rancher/k3s/k3s.yaml > /home/ubuntu/kubeconfig
chown ubuntu:ubuntu /home/ubuntu/kubeconfig
chmod 600 /home/ubuntu/kubeconfig

echo "==> k3s master ready. Token saved to /home/ubuntu/node-token, kubeconfig to /home/ubuntu/kubeconfig"
kubectl get nodes -o wide
