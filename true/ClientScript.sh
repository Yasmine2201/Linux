#!/bin/bash

# Définir une fonction pour vérifier si un package est installé
is_package_installed() {
    dpkg -l "$1" &> /dev/null
    return $?
}

# Définir une fonction pour vérifier et démarrer un service
check_and_start_service() {
    local SERVICE_NAME=$1

    # Obtenir le statut du service
    local STATUS=$(systemctl is-active "$SERVICE_NAME")

    case "$STATUS" in
        active)
            echo "Le service $SERVICE_NAME est actif (en cours d'exécution)."
            ;;
        inactive)
            echo "Le service $SERVICE_NAME est inactif."
            echo "Tentative de démarrage du service $SERVICE_NAME..."
            systemctl start "$SERVICE_NAME"
            local NEW_STATUS=$(systemctl is-active "$SERVICE_NAME")
            if [ "$NEW_STATUS" == "active" ]; then
                echo "Le service $SERVICE_NAME est maintenant actif."
            else
                echo "Le service $SERVICE_NAME n'a pas réussi à démarrer (statut: $NEW_STATUS)."
                exit 1
            fi
            ;;
        failed)
            echo "Le service $SERVICE_NAME a échoué."
            exit 1
            ;;
        *)
            echo "Statut inconnu pour le service $SERVICE_NAME: $STATUS."
            exit 1
            ;;
    esac
}
add_nis_if_missing() {
    local entry="$1"
    echo "Traitement de l'entrée : $entry"
    
    if ! grep -qE "^${entry}:.*nis" "/etc/nsswitch.conf"; then
        echo "Ajout de 'nis' à la ligne ${entry}:"
        sudo sed -i "/^${entry}:/ s/\$/ nis/" "/etc/nsswitch.conf"
        if [ $? -eq 0 ]; then
            echo "'nis' ajouté à ${entry}."
        else
            echo "Erreur lors de l'ajout de 'nis' à ${entry}."
        fi
    else
        echo "'nis' est déjà présent dans ${entry}."
    fi
}

########################################################################################
######################################## NFS/NIS #######################################
########################################################################################

# Vérifier et installer les paquets nécessaires pour NFS et NIS
echo "Vérification des paquets NFS et NIS..."
apt-get update

packages=("rpcbind" "nfs-common" "yp-tools" "nis")

# Vérifier et installer les paquets nécessaires pour NIS
for package in "${packages[@]}"; do
    if is_package_installed "$package"; then
        echo "Le paquet $package est déjà installé."
    else
        echo "Le paquet $package n'est pas installé. Installation..."
        apt install -y "$package"
    fi
done

## NFS ##

# Démarrer et vérifier le statut des services rpcbind
echo "Démarrage du service rpcbind..."
check_and_start_service "rpcbind"

# systemctl status rpcbind

# Créer le répertoire pour monter le /home du serveur
echo "Création du répertoire pour le montage NFS..."
mkdir -p /home/mounted_home


adresse_IP_serveur=server
# Monter le répertoire /home du serveur
echo "Montage du répertoire /home du serveur..."
mount -t nfs $adresse_IP_serveur:/home /home/mounted_home
if [ $? -ne 0 ]; then
  echo "Erreur: le montage NFS a échoué."
  exit 1
fi

# Ajouter l'entrée dans /etc/fstab pour monter au démarrage
echo "Ajout du montage NFS à /etc/fstab..."
grep -qxF "$adresse_IP_serveur:/home /home/mounted_home nfs defaults 0 0" /etc/fstab

if [ $? -ne 0 ]; then
    echo "L'entrée n'existe pas. Ajout de l'entrée au fichier fstab..."
    echo "$adresse_IP_serveur:/home /home/mounted_home nfs defaults 0 0" >> /etc/fstab
else
    echo "L'entrée existe déjà dans /etc/fstab."
fi

## NIS ##

# Déclarer le domaine NIS
echo "Déclaration du domaine NIS..."
echo "projetLinux" > /etc/defaultdomain
domainname projetLinux

# Configurer /etc/yp.conf
echo "Configuration de /etc/yp.conf..."
echo "domain projetLinux server $adresse_IP_serveur" > /etc/yp.conf


# Entrées à vérifier et à modifier si nécessaire
entries=("passwd" "group" "shadow""hosts")

# Vérification et modification des lignes
echo "Vérification et modification des fichiers..."
for entry in "${entries[@]}"; do
    add_nis_if_missing "$entry"
done


# Démarrer les services NIS
echo "Démarrage des services NIS..."
check_and_start_service "ypbind"

#systemctl status ypbind

# Créer des liens symboliques de /home/mounted_home vers /home
echo "Création des liens symboliques pour les utilisateurs..."
for user in $(ls /home/mounted_home); do
  if [ ! -L /home/$user ]; then
    ln -s /home/mounted_home/$user /home/$user
    if [ $? -ne 0 ]; then
      echo "Erreur: impossible de créer le lien symbolique pour $user"
    fi
  fi
done

echo "Configuration du client terminée."
