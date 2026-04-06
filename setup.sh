#!/bin/bash
set -e

if [ -n "$1" ]; then
    INVENTORY_PATH="$(realpath "$1")"
else
    INVENTORY_PATH="$(realpath "$(dirname "$0")/../diplom_ubuntu/main/inventory.ini")"
fi

echo "Using inventory: $INVENTORY_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Bootstrap phase ==="
cd bootstap
terraform init -reconfigure
terraform apply -auto-approve

export AWS_ACCESS_KEY_ID=$(terraform output -raw access_key)
export AWS_SECRET_ACCESS_KEY=$(terraform output -raw secret_key)

echo "=== Main phase ==="
cd ../main
terraform init -reconfigure
terraform apply -auto-approve

echo "=== Kubespray phase ==="
# Установка Ansible, если отсутствует
if ! command -v ansible >/dev/null 2>&1; then
  echo "Ansible not found, installing via apt..."
  sudo apt update && sudo apt install -y ansible
fi

cd
if [ ! -d "kubespray" ]; then
  git clone https://github.com/kubernetes-sigs/kubespray.git
fi
cd kubespray
python3 -m venv venv || true
source venv/bin/activate
pip install -r requirements.txt
ansible-playbook -i "$INVENTORY_PATH" cluster.yml -b -v

echo "Done."