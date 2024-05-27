#!/bin/bash

# Variables
CLIENT_HOST="user1" # Changez ceci avec l'adresse IP ou le nom d'hôte du client
SSH_USER="max2" # Changez ceci avec votre nom d'utilisateur SSH
NISDOMAIN="Projet" # Changez ceci avec votre nom de domaine NIS
NISSERVER="192.168.229.129" # Changez ceci avec le nom ou l'adresse IP de votre serveur NIS
SSH_PASSWORD="a" # Changez ceci avec votre mot de passe SSH

# Variables
SUDO_PASSWORD="a" # Changez ceci avec votre mot de passe sudo

# Fonction pour exécuter une commande sur le client via SSH avec sshpass


# Fonction pour exécuter une commande avec sudo sur le client via SSH avec sshpass




run_sudo_command() {
    sshpass -p "$SSH_PASSWORD" ssh ${SSH_USER}@${CLIENT_HOST}  "echo ${SUDO_PASSWORD} | sudo -S \"${1}\""
}

run_sudo_command "apt update" 
run_sudo_command "apt install -y nis"


run_sudo_command " sed -i '/^NISDOMAIN=/c\NISDOMAIN=${NISDOMAIN}' /etc/default/nis"
run_sudo_command " echo 'NISDOMAIN=${NISDOMAIN}' >> /etc/default/nis"
run_sudo_command "dommainname ${NISDOMAIN}"
#run_sudo_command "systemctl enable ypbind.service"
#run_sudo_command "systemctl start ypbind.service"
#
### Configurer le serveur NIS sur le client
#run_sudo_command "echo 'ypserver ${NISSERVER}' >> /etc/yp.conf"
##
### Mettre à jour nsswitch.conf
#run_sudo_command "sed -i 's/^passwd:.*/passwd: compat nis/' /etc/nsswitch.conf"
#run_sudo_command "sed -i 's/^group:.*/group: compat nis/' /etc/nsswitch.conf"
#run_sudo_command "sed -i 's/^shadow:.*/shadow: compat nis/' /etc/nsswitch.conf"
##
### Démarrer et activer le service NIS sur le client
#run_sudo_command "systemctl start nis"
#run_sudo_command "systemctl enable nis"
##
### Vérifier la connexion NIS
##run_ssh_command "ypcat passwd"
##
#echo "Configuration NIS sur le client ${CLIENT_HOST} terminée."