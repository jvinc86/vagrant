#/bin/bash

echo -e "\n\n----------------------------------------------------------------------------------"
echo -e "----------------------- INSTALAR EL SERVIDOR PUPPET MASTER  ----------------------"
echo -e "----------------------------------------------------------------------------------\n\n"

echo -e "\n[INSTALAR PUPPETSERVER - PASO 1]: Instala puppetserver\n"
sudo apt install puppetserver -y


echo -e "\n[INSTALAR PUPPETSERVER - PASO 2]: Edita archivo de configuración de puppetserver\n"
sed -i 's/2g/1g/g' /etc/default/puppetserver


echo -e "\n[INSTALAR PUPPETSERVER - PASO 3]: Incluye nombres DNS de Master en archivo de configuración 'puppet.conf'\n"
echo "dns_alt_names=puppetmaster,puppetmaster.vincenup.com,puppetmaster.home,puppet " | tee -a /etc/puppetlabs/puppet/puppet.conf


echo -e "\n[INSTALAR PUPPETSERVER - PASO 4]: Agrega ruta de /opt/puppetlabs/bin a PATH del OS\n"
echo 'export PATH=$PATH:/opt/puppetlabs/bin' | tee -a ~/.bashrc
source ~/.bashrc

# cp /opt/puppetlabs/bin/puppet /usr/bin/ -v

echo -e "\n[INSTALAR PUPPETSERVER - PASO 5]: Inicia el servicio de 'puppetserver'\n"
systemctl start puppetserver
systemctl enable puppetserver


echo -e "\n[INSTALAR PUPPETSERVER - PASO 6]: Crea manifiesto 'site.pp' y modulo 'init.pp'\n"
cat <<EOF | tee /etc/puppetlabs/code/environments/production/manifests/site.pp
node 'puppetagent1' {
   include apache2
}
EOF

cat <<EOF | tee /etc/puppetlabs/code/environments/production/manifests/init.pp
class apache2 {
    exec { 'apt':                       
        command => '/usr/bin/apt update'    # Ejecutar comando 'apt update'
    }

    package { 'apache2':                    # Instalar paquete apache2
        ensure => installed,                # Asegura que este instalado
        require => Exec['apt'],             # Requiere 'exec apt' antes de instalar
    }

    service { 'apache2':                    # Configura servicio apache2
        ensure => running,                  # Asegurar que el servicio apache2 este corriendo
        enable  => true,                    # Habilita el servicio a nivel de OS
        require => Package['apache2'],      # Requiere 'package apache2' antes de proceder
    }

    file { '/var/www/html/info.html':           # Crea archivo info.html
        ensure => file,                         # Asegurar que el archivo info.php existe
        content => '<h1> MI SUPER APP!</h1>',   # Codigo html
        require => Package['apache2'],          # Requiere 'package apache2' antes de proceder
        owner => 'root',
        group => 'root',
        mode => '0644'
    }
}
EOF

