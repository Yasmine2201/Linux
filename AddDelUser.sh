#! /bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root" 
   exit 1
fi

read -p " ajouter (A) un user ou supprimé (S): " BOOL

if [ "$BOOL" = "A" ]; then
    read  -p " nom du nouvel user: " username

    if [ id -u "$username" &>/dev/null ];then
        echo "User already exists"
        exit 1
    fi
    
    if [ -z "$(echo "$username" | grep '^[a-zA-Z0-9_-]*$')" ];then
        echo "Invalid username: $username"
        exit 1
    fi
    read -s -p " mot de passe du nouveau user: " password
    echo 
    sudo adduser --disabled-password --gecos "" "$username"    
    if [ $? -eq 0 ]; then
        echo "L'utilisateur $username a été créé avec succès."
        echo "$username:$password" | sudo chpasswd

        # Définir le mot de passe de l'utilisateur

        # Vérifier si le mot de passe a été défini avec succès
        path = $PWD
        
        cd /var/yp
        sudo make

        cd $path


    else
    echo "Erreur lors de la création de l'utilisateur $username."
    fi

    exit 0
fi

    

if [ "$BOOL" = "S" ]; then
    echo "Suppression d'un utilisateur"
    read -p " nom de l'utilisateur à supprimer: " username
    if [ id -u "$username" &>/dev/null ];then
        echo "Invalid username: $username"
        exit 1
    fi

    sudo deluser "$username"
    if [ $? -eq 0 ]; then
        echo "L'utilisateur $username a été supprimé avec succès."
        cd /home
        if [ -d "$username" ]; then
            sudo rm -rf "$username"
            path = $PWD
    
            cd /var/yp
            sudo make

            cd $path
        fi
    else
        echo "Erreur lors de la suppression de l'utilisateur $username."
    fi
    exit 0
else
    echo "Erreur"
    exit 1
fi
