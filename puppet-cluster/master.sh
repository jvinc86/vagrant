#/bin/bash

wget https://apt.puppetlabs.com/puppet7-release-focal.deb
sudo dpkg -i puppet7-release-focal.deb
sudo apt update -y
sudo apt install puppetserver -y

sudo systemctl start puppetserver
sudo systemctl enable puppetserver

# Set Puppet into Path
sudo cp /opt/puppetlabs/bin/puppet /usr/bin/ -v
sudo cp /opt/puppetlabs/puppet/bin/gem /usr/bin/ -v

# Configure the amount of memory you want to allocate to Puppet Server
sudo sed -i 's/JAVA_ARGS="-Xms2g -Xmx2g/JAVA_ARGS="-Xms1g -Xmx1g/g' /etc/default/puppetserver

sudo systemctl restart puppetserver