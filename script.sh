#!/bin/bash
# Script d'installation automatique de la machine Hack The Box "WebVault"
# OS recommandé : Ubuntu Server 22.04

# Mise à jour et installation des paquets nécessaires
apt update && apt upgrade -y
apt install -y apache2 php libapache2-mod-php openssh-server gcc make

# Création de l'utilisateur faible
useradd -m -s /bin/bash Vault
echo "Vault:Vault89!" | chpasswd

# Configuration du serveur web
cat <<EOF > /var/www/html/index.html
<html>
<head><title>WebVault</title></head>
<body>
<h1>Bienvenue sur WebVault</h1>
<p>Une plateforme de stockage sécurisé...</p>
</body>
</html>
EOF

# Création d'une page vulnérable d'upload
mkdir /var/www/html/uploads
chmod 777 /var/www/html/uploads

cat <<EOF > /var/www/html/upload.php
<?php
if(isset(\$_FILES['file'])) {
    \$file_name = \$_FILES['file']['name'];
    move_uploaded_file(\$_FILES['file']['tmp_name'], "uploads/" . \$file_name);
    echo "Upload réussi : uploads/$file_name";
}
?>
<html>
<body>
<form action="" method="POST" enctype="multipart/form-data">
    <input type="file" name="file">
    <input type="submit" value="Uploader">
</form>
</body>
</html>
EOF

# Redémarrage d'Apache
systemctl restart apache2

# Création d'un fichier SUID exploitable
cat <<EOF > /home/Vault/vault.c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
int main() {
    setuid(0);
    system("/bin/bash");
    return 0;
}
EOF

gcc /home/Vault/vault.c -o /usr/local/bin/vault
chown root:root /usr/local/bin/vault
chmod 4755 /usr/local/bin/vault

# Configuration des flags HTB
mkdir -p /home/Vault /root
echo "$(echo -n 'Vault89!' | md5sum | awk '{print $1}')" > /home/Vault/user.txt
chmod 640 /home/Vault/user.txt
chown Vault:Vault /home/Vault/user.txt

echo "$(echo -n 'VaultRoot089!' | md5sum | awk '{print $1}')" > /root/root.txt
chmod 640 /root/root.txt
chown root:root /root/root.txt

# Redirection des fichiers d'historique vers /dev/null
ln -sf /dev/null /root/.bash_history
ln -sf /dev/null /home/Vault/.bash_history
ln -sf /dev/null /home/Vault/.mysql_history
ln -sf /dev/null /home/Vault/.viminfo
chown root:root /root/.bash_history /home/Vault/.bash_history /home/Vault/.mysql_history /home/Vault/.viminfo

# Nettoyage
rm -f /home/Vault/vault.c

echo "Machine WebVault prête ! IP : $(hostname -I)"