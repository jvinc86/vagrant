#!/bin/bash
# 01/06/2022
# Bash script para instalar tanto en el Master como en los Worker: 
#  - Docker
#  - Kubernetes (kubeadm, kubelet, kubectl)
#  - Container Runtime Interface (CRI) llamado: cri-dockerd (de la marca Mirantis)

echo -e "\n\n-------------------------------------------------------------------------------"
echo -e "------------------------ INICIO INSTALACION KUBERNETES ------------------------"
echo -e "-------------------------------------------------------------------------------\n\n"

# echo "[INSTALACION KUBERNETES | PASO 0]: Configura SELinux (RedHat) en el modo permisivo"
# setenforce 0
# sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux


echo -e "\n[INSTALACION KUBERNETES | PASO 1]: Instalar Docker\n"
curl -fsSL https://download.docker.com/linux/$(lsb_release -is | awk '{print tolower($0)}')/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -is | awk '{print tolower($0)}') $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update -y
apt install docker-ce docker-ce-cli containerd.io -y
usermod -aG docker $USER


echo -e "\n[INSTALACION KUBERNETES | PASO 2]: Deshabilitar la swap (memoria en disco)\n"
swapoff -a
sed -i '/swap/d' /etc/fstab


echo -e "\n[INSTALACION KUBERNETES | PASO 3]: Cargar el modulo br_netfilter que permite el trafico VxLAN\n"
modprobe br_netfilter


echo -e "\n[INSTALACION KUBERNETES | PASO 4]: Update the apt package index and install packages needed to use the Kubernetes apt repository\n"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl


echo -e "\n[INSTALACION KUBERNETES | PASO 5]: Download the Google Cloud public signing key\n"
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg


echo -e "\n[INSTALACION KUBERNETES | PASO 6]: Add the Kubernetes APT repository\n"
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list


echo -e "\n[INSTALACION KUBERNETES | PASO 7]: Install kubelet, kubeadm and kubectl, and pin their version\n"
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
# After this the kubelet would be restarting every few seconds, as it waits in a crashloop for kubeadm to tell it what to do

echo -e "\n[INSTALACION KUBERNETES | PASO 8]: Comment the line 'disabled_plugins' in 'config.toml'\n"
sed -i 's/^disabled_plugins.*/#disabled_plugins = ["cri"]/g' /etc/containerd/config.toml
systemctl restart containerd