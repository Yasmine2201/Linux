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
