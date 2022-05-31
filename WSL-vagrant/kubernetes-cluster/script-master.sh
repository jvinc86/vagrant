#!/bin/bash

echo "[PASO 1] Pullar los contenedores requeridos (scheduler, etcd, controller manager, etc.)"
kubeadm config images pull >/dev/null 2>&1

echo "[PASO 2] Inicializar el Cluster Kubernetes, inicializando el Master"
kubeadm init --apiserver-advertise-address=172.16.16.100 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null

echo "[PASO 3] Deployar la red Calico"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml >/dev/null 2>&1

echo "[PASO 4] Generar y guardar el comando para unirse al cluster en /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null