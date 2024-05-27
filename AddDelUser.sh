#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root" 
   exit 1
fi

# Demande le chemin du fichier contenant les utilisateurs
read -p "Chemin du fichier contenant les utilisateurs: " file_path

# Vérifie si le fichier existe
if [[ ! -f "$file_path" ]]; then
    echo "Erreur: Le fichier $file_path n'existe pas"
    exit 1
fi

# Lecture ligne par ligne du fichier
while IFS=' ' read -r action username password; do
    if [[ "$action" = "A" ]]; then
        # Ajout d'un utilisateur
        if id -u "$username" &>/dev/null; then
            echo "Utilisateur $username existe déjà, saut de la création"
            continue
        fi

        if [[ -z "$(echo "$username" | grep '^[a-zA-Z0-9_-]*$')" ]]; then
            echo "Nom d'utilisateur invalide: $username"
            continue
        fi

        sudo adduser --disabled-password --gecos "" "$username"
        if [[ $? -eq 0 ]]; then
            echo "L'utilisateur $username a été créé avec succès."
            echo "$username:$password" | sudo chpasswd

            path=$PWD
            cd /var/yp
            sudo make
            cd $path
        else
            echo "Erreur lors de la création de l'utilisateur $username."
        fi
    elif [[ "$action" = "S" ]]; then
        # Suppression d'un utilisateur
        if ! id -u "$username" &>/dev/null; then
            echo "L'utilisateur $username n'existe pas, saut de la suppression"
            continue
        fi

        sudo deluser --remove-home "$username"
        if [[ $? -eq 0 ]]; then
            echo "L'utilisateur $username a été supprimé avec succès."
                
                path=$PWD
                cd /var/yp
                sudo make
                cd $path
        else
            echo "Erreur lors de la suppression de l'utilisateur $username."
        fi
    else
        echo "Action non reconnue: $action"
    fi
done < "$file_path"

NFS_DIR="/mnt/nfs/shared"
CLIENT_IP_RANGE="192.168.229.130"
SERVER_IP="192.168.229.129" 

sudo apt update
sudo apt install -y nfs-kernel-server

chown nobody:nogroup $NFS_DIR

echo "$NFS_DIR $CLIENT_IP_RANGE(rw,sync,no_subtree_check)" >> /etc/exports

exportfs -ra

echo "Démarrage et activation du service NFS..."
systemctl start nfs-kernel-server
systemctl enable nfs-kernel-server

echo "Configuration du serveur NFS terminée."

CLIENT_HOST="user1" # Changez ceci avec l'adresse IP ou le nom d'hôte du client
SSH_USER="max2" # Changez ceci avec votre nom d'utilisateur SSH
NISDOMAIN="Projet" # Changez ceci avec votre nom de domaine NIS
NISSERVER="192.168.229.129" # Changez ceci avec le nom ou l'adresse IP de votre serveur NIS
SSH_PASSWORD="a" # Changez ceci avec votre mot de passe SSH
SUDO_PASSWORD="a"
CLIENT_IP="192.168.229.130"
MOUNT_POINT="/mnt/nfs/shared"
cd /home/max/CODE/Linux

echo "Installation du client NFS sur le client $CLIENT_IP..."
sshpass -p $SSH_PASS ssh $SSH_USER@$CLIENT_IP "sudo apt update"
sshpass -p $SSH_PASS ssh $SSH_USER@$CLIENT_IP "sudo apt -y nfs-common"
sshpass -p $SSH_PASS ssh $SSH_USER@$CLIENT_IP "sudo apt -y rpcbind"

echo "Création du point de montage sur le client..."
sshpass -p $SSH_PASS ssh $SSH_USER@$CLIENT_IP "sudo mkdir -p $MOUNT_POINT"

echo "Montage du partage NFS sur le client..."
sshpass -p $SSH_PASS ssh $SSH_USER@$CLIENT_IP "sudo mount -t nfs $SERVER_IP:$NFS_DIR $MOUNT_POINT"

echo "Configuration du montage automatique au démarrage sur le client..."
sshpass -p $SSH_PASS ssh $SSH_USER@$CLIENT_IP "echo $SERVER_IP:$NFS_DIR $MOUNT_POINT nfs defaults 0 0 | sudo tee -a /etc/fstab"