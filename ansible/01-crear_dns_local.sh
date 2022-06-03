#!/bin/bash

echo -e "\n\n--------------------------------------------------------------------------------"
echo -e "----------------------- CONFIGURAR DNS LOCAL (/etc/hosts) ----------------------"
echo -e "--------------------------------------------------------------------------------\n\n"

cat << EOF | sudo tee -a /etc/hosts

# Ansible Infra
192.168.56.70 ansiblemaster  ansiblemaster.vincenup.com  ansible
192.168.56.71 srvubuntu1     srvubuntu1.vincenup.com
192.168.56.72 srvubuntu2     srvubuntu2.vincenup.com
192.168.56.61 srvrocky1      srvrocky1.vincenup.com
192.168.56.62 srvrocky2      srvrocky2.vincenup.com
EOF
