#!/bin/bash
# Bash script para inicializar el Master Node, creando oficialmente el Cluster Kubernetes

echo -e "\n\n-----------------------------------------------------------------------------------------"
echo -e "------------------------ INICIALIZACION DEL CLUSTER K8S (MASTER) ------------------------"
echo -e "-----------------------------------------------------------------------------------------\n\n"


echo -e "\n[ INICIAR CLUSTER | PASO 1] Pullar los contenedores requeridos (scheduler, etcd, controller manager, etc.)\n"
kubeadm config images pull --cri-socket unix:///var/run/cri-dockerd.sock


echo -e "\n[ INICIAR CLUSTER | PASO 2] Inicializar el Cluster Kubernetes, inicializando el Master\n"
kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=192.168.0.0/16 --cri-socket unix:///var/run/cri-dockerd.sock | tee /root/cluster_inicializacion.log


echo -e "\n[ INICIAR CLUSTER | PASO 3] Deployar la red Calico\n"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://projectcalico.docs.tigera.io/manifests/calico.yaml | tee /root/deploy_red_calisto.log


echo -e "\n[ INICIAR CLUSTER | PASO 4] Generar y guardar en un archivo el comando para unirse al cluster\n"
kubeadm token create --print-join-command | tee /home/vagrant/incluir_nodo_a_cluster.sh


echo -e "\n[ INICIAR CLUSTER | PASO 5] Agregar en el comando anterior la parte del Container Runtime Interface CRI\n"
sed -i 's/$/ --cri-socket \/\/\/var\/run\/cri-dockerd.sock/' /home/vagrant/incluir_nodo_a_cluster.sh


echo -e "\n[ INICIAR CLUSTER | PASO 6.1] Configurar permisos a USUARIO ROOT para poder ejecutar comandos 'kubectl'\n"
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | tee -a /root/.bashrc
source /root/.bashrc


echo -e "\n[ INICIAR CLUSTER | PASO 6.2] Configurar permisos a USUARIO ANSIBLE para poder ejecutar comandos 'kubectl'\n"
mkdir -p /home/ansible/.kube
cp -i /etc/kubernetes/admin.conf /home/ansible/.kube/config
chown ansible:ansible /home/ansible/.kube/config


echo -e "\n[ INICIAR CLUSTER | PASO 6.3] Configurar permisos a USUARIO VAGRANT para poder ejecutar comandos 'kubectl'\n"
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config


echo -e "\n[ INICIAR CLUSTER | PASO 7] Crear alias 'kubectl' para usuario 'root'\n"
cat <<EOF | tee -a /root/.bashrc
#ALIAS KUBERNETES
alias k='kubectl'
alias kaf='kubectl apply -f'
alias kasd='kubectl autoscale deployment'
alias kcli='kubectl cluster-info'
alias kcfv='kubectl config view'
alias kcp='kubectl cp'
alias kcd='kubectl create deployment'
alias kd='kubectl delete'
alias kdlf='kubectl delete -f'
alias kdld='kubectl delete deployment'
alias kdlp='kubectl delete pod'
alias kdls='kubectl delete service'
alias kdlds='kubectl delete deployment,service'
alias kdd='kubectl describe deployment'
alias kdn='kubectl describe nodes'
alias kdp='kubectl describe pods'
alias kds='kubectl describe service'
alias kdiff='kubectl diff -f'
alias kexec='kubectl exec'
alias kxp='kubectl explain pods'
alias kxd='kubectl expose deployment'
alias kga='kubectl get all'
alias kgcm='kubectl get configmap'
alias kgd='kubectl get deployment'
alias kgdw='kubectl get deployment -o wide'
alias kge='kubectl get events'
alias kgn='kubectl get nodes'
alias kgns='kubectl get namespaces'
alias kgp='kubectl get pods'
alias kgpw='kubectl get pods -o wide'
alias kgpv='kubectl get pv'
alias kgrs='kubectl get replicaset'
alias kgscr='kubectl get secret'
alias kgs='kubectl get services'
alias kgsw='kubectl get services -o wide'
alias kgds='kubectl get daemonsets'
alias kgrc='kubectl get rc'
alias kgin='kubectl get ingress'
alias kgpvc='kubectl get pvc'
alias kgsc='kubectl get sc'
alias kgep='kubectl get ep'
alias kgz='kubectl get pv,pvc,sc,ep'
alias kxdlb='kubectl expose deployment --type=LoadBalancer'
alias kxdlb3000='kubectl expose deployment --type=LoadBalancer --port=3000'
alias kxdnp='kubectl expose deployment --type=NodePort'
alias kxdnp3000='kubectl expose deployment --type=NodePort --port=3000'
alias kdpgc='kubectl describe pods | grep -A 1 -m 1 Containers:'
alias ksid='kubectl set image deployment'
alias ksidnsa='kubectl set image deployment neo superapp=vincenup/superapp:v2'
alias krosd='kubectl rollout status deployment'
alias kda='kubectl delete deployments,pods,services,ingress,replicasets,rc,daemonsets'
alias kdf='kubectl delete -f'
alias klp='kubectl label pods'
alias kl='kubectl logs'
alias kpd='kubectl patch deployment'
alias kpn='kubectl patch node'
alias kpp='kubectl patch pod'
alias kpf='kubectl port-forward'
alias kr='kubectl run'
alias ks='kubectl scale'
alias ksd='kubectl scale deployment'
alias ktp='kubectl top pod'
alias kdla='kubectl delete all'
alias kdlaa='kubectl delete all --all'
EOF
source /root/.bashrc


echo -e "\n[ INICIAR CLUSTER | PASO 7.1] Crear alias 'kubectl' para usuario 'ansible'\n"
cat <<EOF | tee -a /home/ansible/.bashrc
#ALIAS KUBERNETES
alias k='kubectl'
alias kaf='kubectl apply -f'
alias kasd='kubectl autoscale deployment'
alias kcli='kubectl cluster-info'
alias kcfv='kubectl config view'
alias kcp='kubectl cp'
alias kcd='kubectl create deployment'
alias kd='kubectl delete'
alias kdlf='kubectl delete -f'
alias kdld='kubectl delete deployment'
alias kdlp='kubectl delete pod'
alias kdls='kubectl delete service'
alias kdlds='kubectl delete deployment,service'
alias kdd='kubectl describe deployment'
alias kdn='kubectl describe nodes'
alias kdp='kubectl describe pods'
alias kds='kubectl describe service'
alias kdiff='kubectl diff -f'
alias kexec='kubectl exec'
alias kxp='kubectl explain pods'
alias kxd='kubectl expose deployment'
alias kga='kubectl get all'
alias kgcm='kubectl get configmap'
alias kgd='kubectl get deployment'
alias kgdw='kubectl get deployment -o wide'
alias kge='kubectl get events'
alias kgn='kubectl get nodes'
alias kgns='kubectl get namespaces'
alias kgp='kubectl get pods'
alias kgpw='kubectl get pods -o wide'
alias kgpv='kubectl get pv'
alias kgrs='kubectl get replicaset'
alias kgscr='kubectl get secret'
alias kgs='kubectl get services'
alias kgsw='kubectl get services -o wide'
alias kgds='kubectl get daemonsets'
alias kgrc='kubectl get rc'
alias kgin='kubectl get ingress'
alias kgpvc='kubectl get pvc'
alias kgsc='kubectl get sc'
alias kgep='kubectl get ep'
alias kgz='kubectl get pv,pvc,sc,ep'
alias kxdlb='kubectl expose deployment --type=LoadBalancer'
alias kxdlb3000='kubectl expose deployment --type=LoadBalancer --port=3000'
alias kxdnp='kubectl expose deployment --type=NodePort'
alias kxdnp3000='kubectl expose deployment --type=NodePort --port=3000'
alias kdpgc='kubectl describe pods | grep -A 1 -m 1 Containers:'
alias ksid='kubectl set image deployment'
alias ksidnsa='kubectl set image deployment neo superapp=vincenup/superapp:v2'
alias krosd='kubectl rollout status deployment'
alias kda='kubectl delete deployments,pods,services,ingress,replicasets,rc,daemonsets'
alias kdf='kubectl delete -f'
alias klp='kubectl label pods'
alias kl='kubectl logs'
alias kpd='kubectl patch deployment'
alias kpn='kubectl patch node'
alias kpp='kubectl patch pod'
alias kpf='kubectl port-forward'
alias kr='kubectl run'
alias ks='kubectl scale'
alias ksd='kubectl scale deployment'
alias ktp='kubectl top pod'
alias kdla='kubectl delete all'
alias kdlaa='kubectl delete all --all'
EOF
source /home/ansible/.bashrc