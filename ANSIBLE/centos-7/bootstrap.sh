yum update -y
timedatectl set-timezone "Europe/Paris"

yum install -y git vim curl

usuario=vincent
contrasena=123
adduser -U $usuario -m -s /bin/bash -G wheel
echo "$contrasena" | passwd --stdin $usuario
echo "$usuario        ALL=(ALL)       NOPASSWD: ALL" | tee -a /etc/sudoers

echo "$contrasena" | passwd --stdin root
echo "$contrasena" | passwd --stdin vagrant
echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" | tee -a /etc/sudoers

sed -i 's/^%wheel.*/%wheel        ALL=(ALL)       NOPASSWD: ALL/g' /etc/sudoers
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
