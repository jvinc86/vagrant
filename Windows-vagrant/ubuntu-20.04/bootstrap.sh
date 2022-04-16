apt update -y && apt upgrade -y
timedatectl set-timezone Europe/Paris

apt install -y git vim curl

usuario=vincent
contrasena=123
useradd -U $usuario -m -s /bin/bash -G sudo
echo "$usuario:$contrasena" | chpasswd
echo "$usuario ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

echo "root:$contrasena" | chpasswd
echo "vagrant:$contrasena" | chpasswd
echo "vagrant ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

sed -i 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

echo "BRUTAL! Instalacion terminada con exito. Sigue asi!"