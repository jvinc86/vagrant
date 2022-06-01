#!/bin/bash
# Script bootstrap para dejar el Sistema Operativo listo para su uso

echo -e "\n\n-----------------------------------------------------------------------------"
echo -e "----------------------- INICIO DE BOOTSTRAP PARA EL OS ----------------------"
echo -e "-----------------------------------------------------------------------------\n\n"

echo "[PASO 0 - BOOTSTRAP]: Configurar servidor DNS (OJO! Solo en caso de que sea necesario)"
servidor_dns=172.17.128.1
sed -i "s/^nameserver.*/nameserver $servidor_dns/g" /etc/resolv.conf


echo "[PASO 1 - BOOTSTRAP]: Configurar timezone"
timedatectl set-timezone Europe/Paris


echo "[PASO 2 - BOOTSTRAP]: Actualizar repositorios del OS y actualizar paquetes"
apt update && apt upgrade -y           # Debian/Ubuntu
# dnf update -y                          # RedHat/Centos/Rocky


echo "[PASO 3 - BOOTSTRAP]: Permitir accesos por SSH con UserPassword y con Llave"
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
service sshd restart


echo "[PASO 4 - BOOTSTRAP]: No pedir password a usuarios SUDO"
sed -i 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers    # Debian/Ubuntu
# sed -i 's/^%wheel.*/%wheel  ALL=(ALL)  NOPASSWD: ALL/g' /etc/sudoers    # RedHat/Centos/Rocky


echo "[PASO 5 - BOOTSTRAP]: Configurar registros DNS locales"
cat << EOF >> /etc/hosts
# Kubernetes Servidores
192.168.56.80 puppetmaster puppetmaster.vincenup.com
192.168.56.81 puppetagent1 puppetagent1-paris puppetagent1.vincenup.com
192.168.56.82 puppetagent2 puppetagent2-newyork puppetagent2.vincenup.com
192.168.56.83 puppetagent3 puppetagent3-londres puppetagent3.vincenup.com
EOF


echo "[PASO 6 - BOOTSTRAP]: Deshabilitar Firewall"
ufw disable                                              # Debian/Ubuntu
# systemctl stop firewalld && systemctl disable firewalld       # RedHat/Centos/Rocky


#---------  Crear usuario: Comentar la parte que no pertenezca al OS ---------------------
echo "[PASO 7 - BOOTSTRAP]: Agregar un nuevo usuario con permisos administradores (Debian/Ubuntu)"
usuario=ansible
contrasena=123
useradd -U $usuario -m -s /bin/bash -G sudo  # Debian/Ubuntu
echo "$usuario:$contrasena" | chpasswd
echo "$usuario ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers


# echo "[PASO 7 - BOOTSTRAP]: Agregar un nuevo usuario con permisos de Administrador (RedHat/Centos/Rocky)"
# usuario=ansible
# contrasena=123
# useradd -U $usuario -m -s /bin/bash -G wheel # RedHat/Centos/Rocky
# echo "$usuario:$contrasena" | chpasswd
# echo "$usuario ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
#------------------------------------------------------------------------------------------