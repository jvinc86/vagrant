apt-get update -y && apt-get upgrade -y
timedatectl set-timezone Europe/Paris
apt-get install -y default-jdk git vim curl wget tree gnupg2 apache2

echo "export JENKINS_HOME=/var/lib/jenkins" | tee -a /etc/profile
echo "export JAVA_HOME=/usr/lib/jvm/default-java" | tee -a /etc/profile
echo "export MAVEN_HOME=/opt/maven" | tee -a /etc/profile
echo "export GIT_HOME=/usr/bin/git" | tee -a /etc/profile

usuario=jenkins
useradd -U $usuario -m -s /bin/bash -G sudo
echo "$usuario:123" | chpasswd
echo "$usuario ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

echo "vagrant ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers
echo "vagrant:123" | chpasswd
echo "root:123" | chpasswd

usuario=ansibleadmin
useradd -U $usuario -m -s /bin/bash -G sudo
echo "$usuario:123" | chpasswd
echo "$usuario ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g'

sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
service sshd restart

wget -P /tmp https://dlcdn.apache.org/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz
tar -xf /tmp/apache-maven-3.8.5-bin.tar.gz -C /opt
ln -s /opt/apache-maven-3.8.5 /opt/maven

# Jenkins Installation
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update -y
sudo apt install jenkins -y
sudo systemctl start jenkins
