#!/bin/bash

# Fonction
is_package_installed() {
    dpkg -l "$1" &> /dev/null
    return $?
}

add_nis_if_missing() {
    local entry="$1"
    if ! grep -qE "^${entry}:.*nis" $NSSWITCH_FILE; then
        echo "Ajout de 'nis' à la ligne ${entry}:"
        sed -i "/^${entry}:/ s/\$/ nis/" $NSSWITCH_FILE
        echo "'nis' ajouté à ${entry}."
    else
        echo "'nis' est déjà présent dans ${entry}."
    fi
}

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


# Démarrer et vérifier le statut des services rpcbind
echo "Démarrage du service rpcbind..."
systemctl start rpcbind
systemctl status rpcbind

# Créer le répertoire pour monter le /home du serveur
echo "Création du répertoire pour le montage NFS..."
mkdir -p /home/mounted_home


adresse_IP_serveur="192.168.229.129"
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
fi

# Déclarer le domaine NIS
echo "Déclaration du domaine NIS..."
echo "projetLinux" > /etc/defaultdomain
domainname projetLinux

# Configurer /etc/yp.conf
echo "Configuration de /etc/yp.conf..."
echo "domain projetLinux server $adresse_IP_serveur" > /etc/yp.conf


# Entrées à vérifier et à modifier si nécessaire
entries=("passwd" "group" "shadow" "hosts")

# Vérification et modification des lignes
for entry in "${entries[@]}"; do
    add_nis_if_missing "$entry"
done


# Démarrer les services NIS
echo "Démarrage des services NIS..."
systemctl start ypbind
systemctl status ypbind

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
