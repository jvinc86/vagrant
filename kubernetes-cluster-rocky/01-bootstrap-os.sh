#!/bin/bash
# Script bootstrap para dejar el Sistema Operativo listo para su uso

echo -e "\n\n-----------------------------------------------------------------------------"
echo -e "----------------------- INICIO DE BOOTSTRAP PARA EL OS ----------------------"
echo -e "-----------------------------------------------------------------------------\n\n"

# echo -e "\n[PASO 0 - BOOTSTRAP]: Configurar servidor DNS (OJO! Solo en caso de que sea necesario)"
# servidor_dns=172.17.128.1
# sed -i "s/^nameserver.*/nameserver $servidor_dns/g" /etc/resolv.conf


echo -e "\n[PASO 1 - BOOTSTRAP]: Configurar timezone\n"
timedatectl set-timezone Europe/Paris


echo -e "\n[PASO 2 - BOOTSTRAP]: Actualizar repositorios del OS y actualizar paquetes\n"
# apt update && apt upgrade -y           # Debian/Ubuntu
dnf update -y                          # RedHat/Centos/Rocky


echo -e "\n[PASO 3 - BOOTSTRAP]: Permitir accesos por SSH con UserPassword y con Llave\n"
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
service sshd restart


echo -e "\n[PASO 4 - BOOTSTRAP]: No pedir password a usuarios SUDO\n"
# sed -i 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers    # Debian/Ubuntu
sed -i 's/^%wheel.*/%wheel  ALL=(ALL)  NOPASSWD: ALL/g' /etc/sudoers    # RedHat/Centos/Rocky


echo -e "\n[PASO 5 - BOOTSTRAP]: Configurar registros DNS locales\n"
cat << EOF >> /etc/hosts
# Kubernetes Servidores
192.168.56.10 kmaster kmaster.vincenup.com
192.168.56.11 kworker1 kworker-paris kworker1.vincenup.com
192.168.56.12 kworker2 kworker2-newyork kworker2.vincenup.com
192.168.56.13 kworker3 kworker3-londres kworker3.vincenup.com
EOF


echo -e "\n[PASO 6 - BOOTSTRAP]: Deshabilitar Firewall\n"
# ufw disable                                              # Debian/Ubuntu
systemctl stop firewalld && systemctl disable firewalld       # RedHat/Centos/Rocky


#---------  Crear usuario: Comentar la parte que no pertenezca al OS ---------------------
# echo -e "\n[PASO 7 - BOOTSTRAP]: Agregar un nuevo usuario con permisos administradores (Debian/Ubuntu)"
# usuario=ansible
# contrasena=123
# useradd -U $usuario -m -s /bin/bash -G sudo  # Debian/Ubuntu
# echo "$usuario:$contrasena" | chpasswd
# echo "$usuario ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers


echo -e "\n[PASO 7 - BOOTSTRAP]: Agregar un nuevo usuario con permisos de Administrador (RedHat/Centos/Rocky)\n"
usuario=ansible
contrasena=123
useradd -U $usuario -m -s /bin/bash -G wheel # RedHat/Centos/Rocky
echo "$usuario:$contrasena" | chpasswd
echo "$usuario ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
#------------------------------------------------------------------------------------------