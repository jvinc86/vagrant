#!/bin/bash
# Bash script para inicializar el Master Node, creando oficialmente el Cluster Kubernetes

echo "[PASO 1] Pullar los contenedores requeridos (scheduler, etcd, controller manager, etc.)"
kubeadm config images pull --cri-socket unix:///var/run/cri-dockerd.sock

echo "[PASO 2] Inicializar el Cluster Kubernetes, inicializando el Master"
kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=192.168.0.0/16 --cri-socket /run/cri-dockerd.sock | tee /root/cluster_inicializacion.log

echo "[PASO 3] Deployar la red Calico"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://projectcalico.docs.tigera.io/manifests/calico.yaml | tee /root/deploy_red_calisto.log

echo "[PASO 4] Generar y guardar en un archivo el comando para unirse al cluster"
kubeadm token create --print-join-command | tee /home/vagrant/incluir_nodo_a_cluster.sh

echo "[PASO 5] Agregar en el comando anterior la parte del Container Runtime Interface CRI"
sed -i 's/$/ --cri-socket \/run\/cri-dockerd.sock/' /home/vagrant/incluir_nodo_a_cluster.sh

echo "[PASO 6] Configurar permisos a usuario ROOT para poder ejecutar comandos kubectl"
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | tee -a ~/.bashrc
source ~/.bashrc
