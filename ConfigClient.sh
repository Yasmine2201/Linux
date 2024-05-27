#! /bin/bash

read -p "Adresse IP du client: " IP
read -p "Nom du root du client: " CLIENT_ROOT
read -p "Domain NIS: " DOMAIN_NIS
read -p "Serveur NIS: " NIS_SERVEUR  
#verif si rien n'est vide
if [ -z "$IP" ] || [ -z "$CLIENT_ROOT" ] || [ -z "$DOMAIN_NIS" ] || [ -z "$NIS_SERVEUR" ]; then
    echo "Veuillez remplir tous les champs"
    exit 1
fi
CONFIGURE_NIS_CMDS="
sudo apt-get update && sudo apt-get install -y nis rpcbind yp-tools ypbind;
echo 'domain $NIS_DOMAIN server $NIS_SERVER' | sudo tee /etc/yp.conf;
sudo sed -i 's/^\(NISDOMAIN=\).*/\1$NIS_DOMAIN/' /etc/default/nis;
sudo systemctl restart ypbind;
sudo systemctl enable ypbind;
"

