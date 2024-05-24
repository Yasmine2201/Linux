parent=/home/TPUSERS

echo "Username: "
read username

if id -u "$username" &>/dev/null
then
    echo "User already exists"
    exit 1
fi

if [ -z "$(echo "$username" | grep '^[a-zA-Z0-9_-]*$')" ]
then
    echo "Invalid username: $username"
    exit 1
fi

echo "Password: "
read -s password
echo ""

echo "Primary group: "
read primary

echo "Secondary groups, delimited with comas: "
read secondary

for group in $(echo "$primary,$secondary" | tr ' ' '++' | tr ',' ' ')
do
    group=$(echo "$group" | tr '++' ' ')
    if [ -z "$(echo "$group" | grep '^[a-zA-Z0-9_-]*$')" ]
    then
        echo "Invalid group name: $group"
        exit 1
    fi
done

if [ ! -d "$parent" ]
then
    mkdir "$parent"
    chmod o=rx "$parent"
fi

for group in $primary $(echo $secondary | tr ',' ' ')
do
    folder=$parent/$group
    groupfile=$folder/$group.txt

    if [ -z "$(getent group $group)" ]
    then
        groupadd $group;
        echo "Group $group created."
    fi

    if [ ! -d "$folder" ]
    then
        mkdir $folder
        chgrp $group $folder
        chmod 710 $folder
        touch $groupfile
        chgrp $group $groupfile
        chmod 760 $groupfile

        for user in $(groupmems -l -g $group)
		do
            userfile=$folder/$user.txt
			touch $userfile
			chown $user $userfile
			chmod 600 $userfile
		done

        echo "Group folder created: $folder"
    fi
done

useradd -M -p $(openssl passwd "$password") -g $primary -G $primary,$secondary $username
echo "User $username created."

for group in $primary $(echo $secondary | tr ',' ' ')
do
    userfile=$parent/$group/$username.txt
    touch $userfile
    chown $username $userfile
    chmod 600 $userfile
done
echo "Userfiles created."