#!/bin/bash

echo -e "\n\n----------------------------------------------------------------------------"
echo -e "----------------------- INSTALACION DE ANSIBLE MASTER ----------------------"
echo -e "----------------------------------------------------------------------------\n\n"


echo -e "\n[ANSIBLE MASTER - PASO 1]: \n"
apt-get update && apt-get upgrade -y

 
echo -e "\n[ANSIBLE MASTER - PASO 2]: Instalar Ansible desde su repositorio oficial\n"
apt-get install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible


echo -e "\n[ANSIBLE MASTER - PASO 3]: Crear carpeta del Proyecto en el HOME del usuario 'vagrant' \n"
mkdir /home/vagrant/ansible_infra
cd /home/vagrant/ansible_infra


echo -e "\n[ANSIBLE MASTER - PASO 4]: Crear el archivo de configuracion de Ansible\n"
cat << EOF | sudo tee -a /home/vagrant/ansible_infra/ansible.cfg
[defaults]
inventory = inventario.yaml
host_key_checking = False
EOF


echo -e "\n[ANSIBLE MASTER - PASO 5]: Crear el inventario de servidores\n"
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

echo -e "\n[ANSIBLE MASTER - PASO 6]: Crear playbook que servira como BOOTSTRAP\n"
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

    - name: Create ansible user (Debian Family)
      tags: always
      ansible.builtin.user: name=ansible state=present shell=/bin/bash create_home=yes groups=sudo append=yes
      when: ansible_facts['os_family'] == "Debian"

    - name: Create ansible user (RedHat Family)
      tags: always
      ansible.builtin.user: name=ansible state=present shell=/bin/bash create_home=yes groups=wheel append=yes
      when: ansible_facts['os_family'] == "RedHat"

    - name: Set authorized key taken from file
      tags: always
      ansible.posix.authorized_key: user=ansible state=present key="{{ lookup('file', '/home/vagrant/.ssh/ansible-ssh-key.pub') }}"
      register: authorized_key_result
      failed_when:
        - authorized_key_result.msg is defined
        - authorized_key_result.msg is not match('Failed to lookup user')

    - name: Add sudoer file for the ansible user
      tags: always
      copy: src=/home/vagrant/ansible_infra/sudoer_ansible dest=/etc/sudoers.d/ansible owner=root group=root mode=0440
EOF

echo -e "\n[ANSIBLE MASTER - PASO 7]: Crear archivo 'sudoer' para usuario 'ansible'\n"
cat << EOF | sudo tee -a /home/vagrant/ansible_infra/sudoer_ansible
ansible ALL=(ALL:ALL) NOPASSWD: ALL
EOF

echo -e "\n[ANSIBLE MASTER - PASO 8]: Crear playbook con modulo PING (para probar conexiones SSH)\n"
cat << EOF | sudo tee -a /home/vagrant/ansible_infra/conexion_ssh.yaml
---
- hosts: servidores_web
  tasks:
    - name: Probar conexion SSH a los servidores remotos
      ansible.builtin.ping:
EOF


echo -e "\n[ANSIBLE MASTER - PASO 9]: Convertir al usuario 'vagrant' como el usuario OWNER de la carpeta del proyecto\n"
chown -R vagrant:vagrant ansible_infra


echo -e "\n[ANSIBLE MASTER - PASO 10]: Crear un par de llaves SSL para uso de Ansible\n"
ssh-keygen -t ed25519 -b 521 -C "Servidor Ansible Master" -N "" -f /home/vagrant/.ssh/ansible-ssh-key


echo -e "\n[ANSIBLE MASTER - PASO 11]: Copiar 'Llave publica Ansible' a los servidores del inventario\n"
sudo apt-get install sshpass -y
sshpass -p vagrant ssh-copy-id -i /home/vagrant/.ssh/ansible-ssh-key.pub -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@srvubuntu1
sshpass -p vagrant ssh-copy-id -i /home/vagrant/.ssh/ansible-ssh-key.pub -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@srvubuntu2
sshpass -p vagrant ssh-copy-id -i /home/vagrant/.ssh/ansible-ssh-key.pub -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@srvrocky1
# sshpass -p vagrant ssh-copy-id -i /home/vagrant/.ssh/ansible-ssh-key.pub -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@srvrocky2


echo -e "\n[ANSIBLE MASTER - PASO 12]: Ejecutar playbook de conexiones SSH\n"
ansible-playbook /home/vagrant/ansible_infra/conexion_ssh.yaml


echo -e "\n[ANSIBLE MASTER - PASO 13]: Ejecutar playbook BOOTSTRAP con usuario 'vagrant'\n"
ansible-playbook /home/vagrant/ansible_infra/bootstrap.yaml


echo -e "\n[ANSIBLE MASTER - PASO 14]: En el inventario, cambiar usuario 'vagrant' por usuario 'ansible'\n"
sed -i 's/ansible_user: vagrant/ansible_user: ansible/g' /home/vagrant/ansible_infra/inventario.yaml

echo -e "\n[ANSIBLE MASTER - PASO 15]: En el inventario, comentar linea de password\n"
sed -i 's/ansible_password: vagrant/#ansible_password: /g' /home/vagrant/ansible_infra/inventario.yaml

echo -e "\n[ANSIBLE MASTER - PASO 16]: En el inventario, agregar linea para usar llave privada de usuario ansible\n"
sed -i '/ansible_password.*/a \ \ \ \ ansible_ssh_private_key_file: \/home\/vagrant\/.ssh\/ansible-ssh-key' /home/vagrant/ansible_infra/inventario.yaml

echo -e "\n[ANSIBLE MASTER - PASO 17]: Ejecutar playbook BOOTSTRAP con usuario ANSIBLE y su llave privada\n"
ansible-playbook /home/vagrant/ansible_infra/bootstrap.yaml