#!/bin/bash

echo -e "\n\n----------------------------------------------------------------------"
echo -e "----------------------- MINI BOOTSTRAP (UBUNTU) ----------------------"
echo -e "----------------------------------------------------------------------\n\n"

echo -e "\n[SERVIDOR UBUNTU - PASO 1]: Deshabilita el firewall\n"
systemctl stop ufw
systemctl disable ufw

echo -e "\n[SERVIDOR UBUNTU - PASO 2]: Permitir accesos por SSH con UserPassword y con Llave\n"
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd