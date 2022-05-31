#!/bin/bash

echo "[PASO 1 - BOOTSTRAP]: Actualizar paquetes Rocky"
dnf update -y

echo "[PASO 2 - BOOTSTRAP]: Permitir accesos por SSH con UserPassword y con Llave"
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
service sshd restart

echo "[PASO 3 - BOOTSTRAP]: No pedir password a usuarios sudo"
sed -i 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

echo "[PASO 4]: Instalar Docker"
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce
systemctl start docker
systemctl enable docker
usermod -aG docker $USER

echo "[PASO 5]: Configurar registros DNS locales"
cat << EOF >> /etc/hosts
# Kubernetes Servidores
192.168.56.10 kmaster kmaster.vincenup.com
192.168.56.11 kworker1 kworker-paris kworker1.vincenup.com
192.168.56.12 kworker2 kworker2-newyork kworker2.vincenup.com
192.168.56.13 kworker3 kworker3-londres kworker3.vincenup.com
EOF


echo "[PASO 6]: Deshabilitar Firewall"
systemctl stop firewalld
systemctl disable firewalld


echo "[PASO 7]: Deshabilitar la swap (memoria en disco)"
swapoff -a
sed -i '/swap/d' /etc/fstab


echo "[PASO 8]: Configura SELinux en el modo permisivo"
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux


echo "[PASO 9]: Cargar el modulo br_netfilter que permite el trafico VxLAN"
modprobe br_netfilter


echo "[PASO 10]: Crear archivo kube.conf"
cat << EOF >  /etc/sysctl.d/kube.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system 


echo "[PASO 11]: Agrega en yum.repos.d el REPO para los componentes: kubeadm, kubelet, kubectl"
cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF


echo "[PASO 12]: Instalar kubeadm, kubelet, kubectl"
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl start kubelet
systemctl enable kubelet


echo "[PASO 13]: Instalar Mirantis cri-dockerd"
yum -y install git wget curl
VER=$(curl -s https://api.github.com/repos/Mirantis/cri-dockerd/releases/latest|grep tag_name | cut -d '"' -f 4|sed 's/v//g')
echo $VER
wget https://github.com/Mirantis/cri-dockerd/releases/download/v${VER}/cri-dockerd-${VER}.amd64.tgz
tar xvf cri-dockerd-${VER}.amd64.tgz
rm -rf xvf cri-dockerd-${VER}.amd64.tgz
mv cri-dockerd/cri-dockerd /usr/local/bin/


echo "[PASO 14]: Configurar el servicio de Linux para cri-dockerd, es decir, las unidades systemd para cri-dockerd"
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket
mv cri-docker.socket cri-docker.service /etc/systemd/system/
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service


echo "[PASO 15]: Iniciar y habilitar los servicios cri-docker.service y cri-docker.socket"
systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket
systemctl status cri-docker.socket

