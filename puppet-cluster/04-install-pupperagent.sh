#/bin/bash

echo -e "\n\n------------------------------------------------------------------------------------------"
echo -e "-------------------- INSTALAR EN EL SERVIDOR CLIENTE EL AGENTE PUPPET  -------------------"
echo -e "------------------------------------------------------------------------------------------\n\n"


echo -e "\n[INSTALAR AGENTE PUPPET - PASO 1]: Instala 'puppet-agent'\n"
sudo apt install puppet-agent -y


echo -e "\n[INSTALAR AGENTE PUPPET - PASO 2]: Configura archivo 'puppet.conf' con datos de Master Puppet\n"
cat <<EOF | tee -a /etc/puppetlabs/puppet/puppet.conf
[main]
certname = $(hostname)
server = puppetmaster
environment = production
runinterval = 30m
EOF


echo -e "\n[INSTALAR AGENTE PUPPET - PASO 3]: Inicia y habilita servicio de puppet (agent)\n"
sudo systemctl start puppet
sudo systemctl enable puppet


echo -e "\n[INSTALAR AGENTE PUPPET - PASO 4]: Agrega ruta '/opt/puppetlabs/bin' a PATH del OS\n"
echo 'export PATH=$PATH:/opt/puppetlabs/bin' | tee -a ~/.bashrc
source ~/.bashrc