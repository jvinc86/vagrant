#!/bin/bash

echo "[PASO 1]: Meter el WorkerNode al Cluster"
apt install -qq -y sshpass >/dev/null 2>&1
sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster:/joincluster.sh /joincluster.sh 2>/dev/null
sshpass -p 'vagrant' scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@kmaster:holavagr.txr /home/vcamacho/holavagr.txr
bash /joincluster.sh >/dev/null 2>&1




sshpass -p 'vagrant' scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster:holavagr.txr /home/vcamacho/holavagr.txr
sshpass -p 'vagrant' ssh -o StrictHostKeyChecking=no vagrant@kmaster "ls /home/vagrant"
sshpass -p 'vagrant' scp file.tar.gz root@xxx.xxx.xxx.194:/backup 