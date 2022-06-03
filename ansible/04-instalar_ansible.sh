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


echo -e "\n[ANSIBLE MASTER - PASO 3]: Crear usuario 'ansible' en servidor MASTER\n"
usuario=ansible; contrasena=123
useradd -U $usuario -m -s /bin/bash -G sudo
echo "$usuario:$contrasena" | chpasswd


echo -e "\n[ANSIBLE MASTER - PASO 4]: Crear carpeta del PROYECTO en el HOME del usuario 'ansible' \n"
mkdir /home/ansible/ansible_infra
cd /home/ansible/ansible_infra


echo -e "\n[ANSIBLE MASTER - PASO 5]: Crear el archivo de configuracion de Ansible\n"
cat << EOF | sudo tee -a /home/ansible/ansible_infra/ansible.cfg
[defaults]
inventory = inventario.yaml
host_key_checking = False
EOF


echo -e "\n[ANSIBLE MASTER - PASO 6]: Crear el inventario de servidores\n"
cat << EOF | sudo tee -a /home/ansible/ansible_infra/inventario.yaml
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


echo -e "\n[ANSIBLE MASTER - PASO 7]: Crear playbook que servira como BOOTSTRAP\n"
cat << EOF | sudo tee -a /home/ansible/ansible_infra/bootstrap.yaml
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

    - name: Configurar timezone de Paris
      community.general.timezone:
        name: Europe/Paris

    - name: Instalar paquetes requeridos
      ansible.builtin.package: name={{ item }} state=latest update_cache=yes
      loop: [ 'sudo', 'git', 'vim', 'curl', 'gnupg2', 'gnupg', 'wget' ]

    - name: Crear usuario 'ansible' (Familia Debian)
      tags: always
      ansible.builtin.user: name=ansible state=present shell=/bin/bash create_home=yes groups=sudo append=yes
      when: ansible_facts['os_family'] == "Debian"

    - name: Crear usuario 'ansible' (Familia RedHat)
      tags: always
      ansible.builtin.user: name=ansible state=present shell=/bin/bash create_home=yes groups=wheel append=yes
      when: ansible_facts['os_family'] == "RedHat"

    - name: Configurar llave en 'authorized_key' del usuario 'ansible'
      tags: always
      ansible.posix.authorized_key: user=ansible state=present key="{{ lookup('file', '/home/ansible/.ssh/ansible-ssh-key.pub') }}"
      register: authorized_key_result
      failed_when:
        - authorized_key_result.msg is defined
        - authorized_key_result.msg is not match('Failed to lookup user')

    - name: Agregar archivo 'sudoer' para el usuario ansible
      tags: always
      copy: src=/home/ansible/ansible_infra/sudoer_ansible dest=/etc/sudoers.d/ansible owner=root group=root mode=0440
EOF


echo -e "\n[ANSIBLE MASTER - PASO 8]: Crear archivo 'sudoer' para usuario 'ansible'\n"
cat << EOF | sudo tee -a /home/ansible/ansible_infra/sudoer_ansible
ansible ALL=(ALL:ALL) NOPASSWD: ALL
EOF


echo -e "\n[ANSIBLE MASTER - PASO 9]: Crear playbook con modulo PING (para probar conexiones SSH)\n"
cat << EOF | sudo tee -a /home/ansible/ansible_infra/conexion_ssh.yaml
---
- hosts: servidores_web
  tasks:
    - name: Probar conexion SSH a los servidores remotos
      ansible.builtin.ping:
EOF


echo -e "\n[ANSIBLE MASTER - PASO 10]: Convertir al usuario 'ansible' como el usuario OWNER de la carpeta del PROYECTO\n"
chown -R ansible:ansible /home/ansible/ansible_infra/


echo -e "\n[ANSIBLE MASTER - PASO 11]: Crear un par de llaves SSL para el usuario 'ansible' en el servidor Ansible Master\n"
mkdir /home/ansible/.ssh/
chown ansible:ansible /home/ansible/.ssh/
chmod 700 /home/ansible/.ssh/
ssh-keygen -t ed25519 -b 521 -C "Servidor Ansible Master" -N "" -f /home/ansible/.ssh/ansible-ssh-key

echo -e "\n[ANSIBLE MASTER - PASO 12]: Cambiar owner de llave recien creada al usuario 'ansible' en el servidor Ansible Master\n"
chown -R ansible:ansible /home/ansible/.ssh/ansible-ssh-key*

echo -e "\n[ANSIBLE MASTER - PASO 13]: Copiar remotamente la 'llave publica Ansible' a cada servidor del INVENTARIO\n"
sudo apt-get install sshpass -y
sshpass -p vagrant ssh-copy-id -i /home/ansible/.ssh/ansible-ssh-key.pub -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@srvubuntu1
sshpass -p vagrant ssh-copy-id -i /home/ansible/.ssh/ansible-ssh-key.pub -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@srvubuntu2
sshpass -p vagrant ssh-copy-id -i /home/ansible/.ssh/ansible-ssh-key.pub -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@srvrocky1
# sshpass -p vagrant ssh-copy-id -i /home/ansible/.ssh/ansible-ssh-key.pub -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@srvrocky2


echo -e "\n[ANSIBLE MASTER - PASO 14]: Ejecutar playbook de conexiones SSH con usuario 'vagrant' definido en el INVENTARIO para conectar por SSH a los SERVIDORES\n"
ansible-playbook /home/ansible/ansible_infra/conexion_ssh.yaml


echo -e "\n[ANSIBLE MASTER - PASO 15]: Ejecutar playbook BOOTSTRAP con usuario 'vagrant' definido en el INVENTARIO para conectar por SSH a los SERVIDORES\n"
ansible-playbook /home/ansible/ansible_infra/bootstrap.yaml


# ---- Despues de este paso y si el bootstrap.yaml corrio bien, se tuvo que hacer creado el usuario 'ansible' en TODOS los SERVIDORES a traves del Playbook BOOTSTRAP


echo -e "\n[ANSIBLE MASTER - PASO 16.1]: En el INVENTARIO, cambiar usuario 'vagrant' por usuario 'ansible' que existe ya en los SERVIDORES\n"
sed -i 's/ansible_user.*/ansible_user: ansible/g' /home/ansible/ansible_infra/inventario.yaml

echo -e "\n[ANSIBLE MASTER - PASO 16.2]: En el INVENTARIO, comentar linea de password, porque ahora nos conectaremos con llave SSH\n"
sed -i 's/ansible_password.*/#ansible_password: /g' /home/ansible/ansible_infra/inventario.yaml

echo -e "\n[ANSIBLE MASTER - PASO 16.3]: En el INVENTARIO, agregar linea para usar llave privada de usuario 'ansible'\n"
sed -i '/ansible_password.*/a \ \ \ \ ansible_ssh_private_key_file: \/home\/ansible\/.ssh\/ansible-ssh-key' /home/ansible/ansible_infra/inventario.yaml


echo -e "\n[ANSIBLE MASTER - PASO 17]: Ejecutar playbook BOOTSTRAP con usuario 'ansible' y su llave privada, ambas cosas ya definidas en el INVENTARIO\n"
ansible-playbook /home/ansible/ansible_infra/bootstrap.yaml