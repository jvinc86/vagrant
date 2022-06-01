#!/bin/bash
# BOOTSTRAP para dejar configurado y preparado el sistema operativo

# Actualizar repositorios APT y hacer upgrade de paquetes
sudo apt update && sudo apt upgrade -y

# Configurar timezone
sudo timedatectl set-timezone Europe/Paris

#Agregar otro usuario para que administre Ansible
usuario=ansible
contrasena=123
sudo useradd -U $usuario -m -s /bin/bash -G sudo
echo "$usuario:$contrasena" | chpasswd

#Evitar que pida el password a cada rato para usuarios que sean parte del grupo sudo
sed -i 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

#Agregar al sudoers este nuevo usuario
echo "$usuario ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

#Deshabilitar firewall
sudo ufw disable

# Permitir accesos por SSH con UserPassword y con Llave
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo service sshd restart