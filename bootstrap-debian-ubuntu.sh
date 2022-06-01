apt-get update -y && apt-get upgrade -y
timedatectl set-timezone Europe/Paris

sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

sed -i 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

usuario=vincent
contrasena=123
useradd -U $usuario -m -s /bin/bash -G sudo
echo "$usuario:$contrasena" | chpasswd
echo "$usuario ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

echo "vagrant ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers
echo "vagrant:123" | chpasswd
echo "root:123" | chpasswd

usuario=ansible
useradd -U $usuario -m -s /bin/bash -G sudo
echo "$usuario:123" | chpasswd
echo "$usuario ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

apt-get install -y git vim curl wget tree

echo "BOOTSTRAP FINALIZO! El servidor esta listo para su uso"