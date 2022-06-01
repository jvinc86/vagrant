#!/bin/bash
# Bash script para unir los worker nodes al Cluster Kubernetes

echo "[PASO 1]: Instalar paquete SSHPass"
yum install sshpass -y


echo "[PASO 2]: Extraer desde Master el comando para unir (join) el Worker Node al Cluster"
sshpass -p 'vagrant' scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@kmaster:incluir_nodo_a_cluster.sh /root/incluir_nodo_a_cluster.sh


echo "[PASO 3]: Correr el comando para unir (join) el Worker Node al Cluster"
bash /root/incluir_nodo_a_cluster.sh