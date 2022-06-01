#/bin/bash

sudo apt install puppet-agent -y

cat <<EOF | tee -a /etc/puppetlabs/puppet/puppet.conf
[main]
certname = $(hostname)
server = puppetmaster
environment = production
runinterval = 30m
EOF

sudo systemctl start puppet
sudo systemctl enable puppet