#!/bin/bash
# k3s WORKER node installation
# Usage: sudo bash k3s-worker.sh <MASTER_IP> <MASTER_NODE_TOKEN> <WORKER_PUBLIC_IP> <NODE_NAME>
#  joins this node to the k3s master using the token extracted from the master
set -euo pipefail

MASTER_IP="$1"
K3S_TOKEN="$2"
WORKER_PUBLIC_IP="$3"
NODE_NAME="$4"

echo "==> Setting hostname to $NODE_NAME"
hostnamectl set-hostname "$NODE_NAME"

echo "==> Installing k3s agent, joining https://$MASTER_IP:6443"
curl -sfL https://get.k3s.io | K3S_URL="https://$MASTER_IP:6443" K3S_TOKEN="$K3S_TOKEN" INSTALL_K3S_EXEC="agent --node-name $NODE_NAME --node-external-ip $WORKER_PUBLIC_IP" sh -

echo "==> $NODE_NAME joined the master"
