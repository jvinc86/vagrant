#!/bin/bash

systemctl stop ufw
systemctl disable ufw
sed -i 's/PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd