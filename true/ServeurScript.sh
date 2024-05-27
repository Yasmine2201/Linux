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

########################################################################################
######################################### NFS ##########################################
########################################################################################

# Vérifier et installer les paquets nécessaires pour NFS
echo "Vérification des paquets NFS..."
apt-get update
packages_nfs=("nfs-server" "rpcbind")

for package in "${packages_nfs[@]}"; do
    if is_package_installed "$package"; then
        echo "Le paquet $package est déjà installé."
    else
        echo "Le paquet $package n'est pas installé. Installation..."
        apt install -y "$package"
    fi
done


# Démarrer et vérifier le statut des services NFS

# Définir le tableau des services
services_nfs=("nfs-server" "rpcbind")

# Boucle pour vérifier et démarrer chaque service
for SERVICE_NAME in "${services_nfs[@]}"; do
    check_and_start_service "$SERVICE_NAME"
done

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
######################################### NIS ##########################################
########################################################################################

packages_nis=("ypserv" "rpcbind")

# Vérifier et installer les paquets nécessaires pour NIS
for package in "${packages_nis[@]}"; do
    if is_package_installed "$package"; then
        echo "Le paquet $package est déjà installé."
    else
        echo "Le paquet $package n'est pas installé. Installation..."
        apt install -y "$package"
    fi
done


# Démarrer et vérifier le statut des services NIS
echo "Démarrage des services NIS..."

services=("ypserv" "rpcbind") 
# Boucle pour vérifier et démarrer chaque service
for SERVICE_NAME in "${services[@]}"; do
    check_and_start_service "$SERVICE_NAME"
done

# Déclarer le domaine NIS
echo "Déclaration du domaine NIS..."
echo "projetLinux" > /etc/defaultdomain
domainname projetLinux

# Modification manuelle du MakeFilefait pour inclure passwd, group, hosts, shadow fait 

# Ajout ou Suppression des utilisateurs

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

        adduser --disabled-password --gecos "" "$username"
        if [[ $? -eq 0 ]]; then
            echo "L'utilisateur $username a été créé avec succès."
            echo "$username:$password" | chpasswd
        else
            echo "Erreur lors de la création de l'utilisateur $username."
        fi

    elif [[ "$action" = "S" ]]; then
        # Suppression d'un utilisateur
        if ! id -u "$username" &>/dev/null; then
            echo "L'utilisateur $username n'existe pas"
            continue
        fi

        deluser --remove-home "$username"
        if [[ $? -eq 0 ]]; then
            echo "L'utilisateur $username a été supprimé avec succès."
        else
            echo "Erreur lors de la suppression de l'utilisateur $username."
        fi
    else
        echo "Action non reconnue: $action"
    fi
done < "$file_path"

# Mettre à jour les maps NIS
make -C /var/yp

# Démarrer le service yppasswdd
check_and_start_service "yppasswdd"

# Fin de la configuration serveur
echo "Configuration du serveur terminée."
