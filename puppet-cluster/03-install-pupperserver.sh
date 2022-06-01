#/bin/bash

sudo apt install puppetserver -y
sed -i 's/2g/1g/g' /etc/default/puppetserver
echo "dns_alt_names=puppetmaster,puppet" | tee -a /etc/puppetlabs/puppet/puppet.conf

echo 'export PATH=$PATH:/opt/puppetlabs/bin' | tee -a ~/.bashrc
source ~/.bashrc

cp /opt/puppetlabs/bin/puppet /usr/bin/ -v

systemctl start puppetserver
systemctl enable puppetserver