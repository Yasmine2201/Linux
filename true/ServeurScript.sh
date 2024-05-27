#!/bin/bash

# Fonction

is_package_installed() {
    dpkg -l "$1" &> /dev/null
    return $?
}

# Vérifier et installer les paquets nécessaires pour NFS
echo "Vérification des paquets NFS..."
apt-get update
packages1=("nfs-server" "rpcbind")

for package in "${packages[@]}"; do
    if is_package_installed "$package"; then
        echo "Le paquet $package est déjà installé."
    else
        echo "Le paquet $package n'est pas installé. Installation..."
        apt install -y "$package"
    fi
done


# Démarrer et vérifier le statut des services NFS
echo "Démarrage des services NFS..."
systemctl start nfs-server
systemctl start rpcbind
systemctl status nfs-server
systemctl status rpcbind

# Déclarer le répertoire à exporter dans /etc/exports
echo "Déclaration du répertoire à exporter..."

# Vérifier si la ligne existe déjà dans le fichier /etc/exports
grep -qxF "/home *(rw)" /etc/exports

if [[ $? -ne 0 ]]; then
    echo "La ligne n'existe pas. Ajout de la ligne au fichier exports..."
    echo "/home *(rw)" >> /etc/exports
fi
# Recharger les exports
exportfs -arv

# Vérifier les exports avec showmount
echo "Vérification des exports..."
showmount --e

########################################################################################
########################################################################################
########################################################################################

packages2=("ypserv" "rpcbind")

# Vérifier et installer les paquets nécessaires pour NIS
for package in "${packages2[@]}"; do
    if is_package_installed "$package"; then
        echo "Le paquet $package est déjà installé."
    else
        echo "Le paquet $package n'est pas installé. Installation..."
        apt install -y "$package"
    fi
done


# Démarrer et vérifier le statut des services NIS
echo "Démarrage des services NIS..."

services=("ypserv" "rpcbind" "yppasswdd") # Ajoutez d'autres services si nécessaire

# Boucle sur chaque service dans le tableau
for SERVICE_NAME in "${services[@]}"; do
    # Obtenir le statut du service
    STATUS=$(systemctl is-active "$SERVICE_NAME")

    # Afficher le statut
    if [ "$STATUS" == "active" ]; then
        echo "Le service $SERVICE_NAME est actif (en cours d'exécution)."
    elif [ "$STATUS" == "inactive" ]; then
        echo "Le service $SERVICE_NAME est inactif."
        
        systemctl start $SERVICE_NAME

        echo "Le service $SERVICE_NAME démarre."
        
        resultat=$(systemctl is-active "$SERVICE_NAME")

        if [ "$resultat" == "failed" ]; then
            echo "Le service $SERVICE_NAME n'a pas réussi à démarrer (failed)(exit)."
            exit 1
        elif [ "$resultat" == "inactive" ]; then
                echo "Le service $SERVICE_NAME n'a pas réussi à démarrer (inactive)(exit)."
                exit 1
        else
            echo "Le service $SERVICE_NAME est actif (en cours d'exécution)."
        fi

    elif [ "$STATUS" == "failed" ]; then
        echo "Le service $SERVICE_NAME a échoué."
        exit 1
    fi
done


# Déclarer le domaine NIS
echo "Déclaration du domaine NIS..."
echo "projetLinux" > /etc/defaultdomain
domainname projetLinux

# Modification du MakeFilefait pour inclure passwd, group, hosts, shadow fait manuellement


########################################################################################
########################################################################################
########################################################################################

echo "ajout/suppression de(s) l'utilisateur(s)"

read -p "Chemin du fichier contenant les utilisateurs: " file_path

# Vérifie si le fichier existe
if [[ ! -f "$file_path" ]]; then
    echo "Erreur: Le fichier $file_path n'existe pas"
    exit 1
fi

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
        else
            echo "Erreur lors de la création de l'utilisateur $username."
        fi

    elif [[ "$action" = "S" ]]; then
        # Suppression d'un utilisateur
        if ! id -u "$username" &>/dev/null; then
            echo "L'utilisateur $username n'existe pas"
            continue
        fi

        sudo deluser --remove-home "$username"
        if [[ $? -eq 0 ]]; then
            echo "L'utilisateur $username a été supprimé avec succès."
        else
            echo "Erreur lors de la suppression de l'utilisateur $username."
        fi
    else
        echo "Action non reconnue: $action"
    fi
done < "$file_path"

make -C /var/yp

systemctl restart ypserv
systemctl restart yppasswdd

echo "Configuration du serveur terminée."
