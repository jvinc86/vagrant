#/bin/bash

echo -e "\n\n---------------------------------------------------------------------------------------"
echo -e "----------------------- CONFIGURAR REPOSITORIO APT DE PUPPETLABS ----------------------"
echo -e "---------------------------------------------------------------------------------------\n\n"


echo -e "\n[REPO PUPPETLABS - PASO 1]: Descarga el .deb que ayudara a definir la fuente oficial para descargar puppet\n"
wget https://apt.puppetlabs.com/puppet7-release-$(lsb_release -cs).deb


echo -e "\n[REPO PUPPETLABS - PASO 2]: Configura la fuente oficial de donde descargar puppet\n"
dpkg -i puppet7-release-$(lsb_release -cs).deb


echo -e "\n[REPO PUPPETLABS - PASO 3]: Actualiza repositorio de paquetes APT (Ahora con Puppetlabs incluido)\n"
apt update -y