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