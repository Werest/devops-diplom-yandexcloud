# Основная инфраструктура (VPC, ВМ, K8s)

**Важно**: для self-managed Kubernetes потребуется как минимум 3 машины (1 мастер + 2 воркера). 
При желании можно добавить ещё одну мастер-ноду для отказоустойчивости, но с учётом бюджета оставляем одну мастер-ноду.

```
chmod +x setup.sh

terraform output -raw access_key
terraform output -raw secret_key

terraform output -raw service_account_id

export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
```

## Запуск Kubespray
```commandline
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
pip install -r requirements.txt
ansible-playbook -i ../inventory.ini cluster.yml -b -v
```
После завершения на мастере будет настроен kubectl.
scp ubuntu@<master_ip>:.kube/config ~/.kube/config

```commandline
kubectl get nodes
kubectl get pods --all-namespaces
```
