#!/bin/bash

set -e

# ───── Basic Setup ─────
echo "[*] Updating system and installing dependencies..."
apt update -y && apt upgrade -y
apt install -y apache2 php php-cli unzip curl

# ───── Web App Deployment ─────
echo "[*] Deploying vulnerable note-taking app..."
rm -rf /var/www/html/*
mkdir -p /var/www/html/uploads

cat <<EOF > /var/www/html/index.php
<?php
if (isset($_FILES['file'])) {
    \$name = \$_FILES['file']['name'];
    \$tmp = \$_FILES['file']['tmp_name'];
    if (preg_match('/\.(jpg|jpeg|png|txt|pdf)$/i', \$name)) {
        move_uploaded_file(\$tmp, "uploads/" . \$name);
        echo "Uploaded!";
    } else {
        echo "Invalid file type.";
    }
}
?>
<!DOCTYPE html>
<html>
<head><title>VaultNote</title></head>
<body>
<h1>VaultNote</h1>
<form method="POST" enctype="multipart/form-data">
  <input type="file" name="file"><br><br>
  <input type="submit" value="Upload">
</form>
</body>
</html>
EOF

# ───── Fake .env File ─────
cat <<EOF > /var/www/html/.env
DB_USER=vaultnote
DB_PASS=VaultNoteUSER01!
APP_KEY=base64:FAKEKEY==
EOF

chown -R www-data:www-data /var/www/html

# ───── Flags ─────
echo "[*] Setting up flags..."

USER_HASH=$(echo -n "VaultNoteUSER01!" | md5sum | cut -d ' ' -f1)
ROOT_HASH=$(echo -n "VaultNote01!" | md5sum | cut -d ' ' -f1)

echo "$USER_HASH" > /home/vaultnote/user.txt
chown root:vaultnote /home/vaultnote/user.txt
chmod 644 /home/vaultnote/user.txt

echo "$ROOT_HASH" > /root/root.txt
chown root:root /root/root.txt
chmod 640 /root/root.txt

# ───── Cron PrivEsc ─────
echo "[*] Setting up vulnerable cron job..."
mkdir -p /opt/vaultnote/
cat <<EOF > /opt/vaultnote/cleaner.sh
#!/bin/bash
source /home/vaultnote/note_list.txt
EOF
chmod +x /opt/vaultnote/cleaner.sh
chown root:root /opt/vaultnote/cleaner.sh

echo "* * * * * root /opt/vaultnote/cleaner.sh" > /etc/cron.d/clean_vaultnote

# ───── Note File (controlled by user) ─────
echo "# empty" > /home/vaultnote/note_list.txt
chown vaultnote:vaultnote /home/vaultnote/note_list.txt

# ───── Cleanup ─────
echo "[*] Securing history files..."
echo "export HISTFILE=/dev/null" >> /etc/profile
echo "export HISTFILE=/dev/null" >> /root/.bashrc
echo "export HISTFILE=/dev/null" >> /home/vaultnote/.bashrc

# ───── Finish ─────
echo "[+] VaultNote installation complete!"
