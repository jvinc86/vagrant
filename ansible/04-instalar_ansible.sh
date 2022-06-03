#!/bin/bash

# Actualizar repo y Upgrade paquetes
apt-get update
apt-get upgrade -y

# Instalar Ansible
apt-get install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

#Crear carpeta para playbooks Ansible
mkdir /home/vagrant/ansible_infra
cd /home/vagrant/ansible_infra

# Crear archivos Ansible
cat << EOF | sudo tee -a /home/vagrant/ansible_infra/ansible.cfg
[defaults]
inventory = inventario.yaml
EOF

# Crear inventario
cat << EOF | sudo tee -a /home/vagrant/ansible_infra/inventario.yaml
---
servidores_web:
  hosts:
    bigdata:
      ansible_host: srvubuntu1
    blockchain:
      ansible_host: srvubuntu2
    paginaweb:
      ansible_host: srvrocky1
  vars:
    ansible_user: vagrant
    ansible_password: vagrant

servidores_bd:
    mysql:
      ansible_host: srvrocky2
  vars:
    ansible_user: vagrant
    ansible_password: vagrant
EOF


# Crear playbook
cat << EOF | sudo tee -a /home/vagrant/ansible_infra/bootstrap.yaml
---
- hosts: servidores_web
  become: yes
  tasks:
    - name: Actualizar repo APT (Familia Debian)
      apt:
        update_cache: yes
        upgrade: yes
      when: ansible_facts['os_family'] == "Debian"

    - name: Actualizar repo YUM (Familia RedHat)
      ansible.builtin.dnf:
        update_cache: yes
        update_only: yes
      when: ansible_facts['os_family'] == "RedHat"

    - name: Permite autenticacion por Password y Usuario
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        state: present
        regexp: ^(# *)?PasswordAuthentication no.*
        line: PasswordAuthentication yes

    - name: Permite autenticacion con llave SSH
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        state: present
        regexp: ^(# *)?PubkeyAuthentication.*
        line: PubkeyAuthentication yes
      notify: Restart sshd

    - name: No pedir password a usuario que esten en grupo SUDO (Familia Debian)
      ansible.builtin.lineinfile:
        path: /etc/sudoers
        state: present
        regexp: "^%sudo.*"
        line: "%sudo ALL=(ALL:ALL) NOPASSWD: ALL"
        validate: /usr/sbin/visudo -cf %s
      when: ansible_facts['os_family'] == "Debian"

    - name: No pedir password a usuario que esten en grupo SUDO (Familia RedHat)
      ansible.builtin.lineinfile:
        path: /etc/sudoers
        state: present
        regexp: "^%wheel.*"
        line: "%wheel        ALL=(ALL)       NOPASSWD: ALL"
        validate: /usr/sbin/visudo -cf %s
      when: ansible_facts['os_family'] == "RedHat"

    - name: Reinicia el servicio sshd (si hay cambios)
      ansible.builtin.service:
        name: sshd
        state: restarted

    - name: Set the timezone to Paris
      community.general.timezone:
        name: Europe/Paris

    - name: Install required system packages
      ansible.builtin.package: name={{ item }} state=latest update_cache=yes
      loop: [ 'sudo', 'git', 'vim', 'curl', 'gnupg2', 'gnupg', 'wget' ]

EOF

# Crear playbook con modulo PING (para probar conexiones SSH)
cat << EOF | sudo tee -a /home/vagrant/ansible_infra/conexion_ssh.yaml
---
- hosts: servidores_web
  tasks:
    - name: Probar conexion SSH a los servidores remotos
      ansible.builtin.ping:
EOF

# Generar llave SSH key
ssh-keygen -t ed25519 -b 521 -C "Servidor Ansible Master" -N "" -f /home/vagrant/.ssh/ansible-ssh-key

# Copiar llaves a servidores
sudo apt install sshpass -y
sshpass -p vagrant ssh-copy-id -i /home/vagrant/.ssh/ansible-ssh-key.pub -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@srvubuntu1
sshpass -p vagrant ssh-copy-id -i /home/vagrant/.ssh/ansible-ssh-key.pub -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@srvubuntu2
sshpass -p vagrant ssh-copy-id -i /home/vagrant/.ssh/ansible-ssh-key.pub -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@srvrocky1
# sshpass -p vagrant ssh-copy-id -i /home/vagrant/.ssh/ansible-ssh-key.pub vagrant@srvrocky2

# Probar playbook
ansible-playbook /home/vagrant/ansible_infra/conexion_ssh.yaml
ansible-playbook /home/vagrant/ansible_infra/bootstrap.yaml
