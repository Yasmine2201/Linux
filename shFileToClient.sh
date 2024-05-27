CLIENT_HOST="user1" # Changez ceci avec l'adresse IP ou le nom d'hôte du client
SSH_USER="max2" # Changez ceci avec votre nom d'utilisateur SSH
NISDOMAIN="Projet" # Changez ceci avec votre nom de domaine NIS
NISSERVER="192.168.229.129" # Changez ceci avec le nom ou l'adresse IP de votre serveur NIS
SSH_PASSWORD="a" # Changez ceci avec votre mot de passe SSH
SUDO_PASSWORD="a"
CLIENT_IP="192.168.229.130"
MOUNT_POINT="/mnt/nfs/shared"

apt update
apt -y nfs-common
apt -y rpcbind
mkdir -p $MOUNT_POINT
mount -t nfs $SERVER_IP:$NFS_DIR $MOUNT_POINT
echo $SERVER_IP:$NFS_DIR $MOUNT_POINT nfs defaults 0 0 | sudo tee -a /etc/fstab