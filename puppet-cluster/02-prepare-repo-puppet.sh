#/bin/bash

wget https://apt.puppetlabs.com/puppet7-release-$(lsb_release -cs).deb
dpkg -i puppet7-release-$(lsb_release -cs).deb
apt update -y