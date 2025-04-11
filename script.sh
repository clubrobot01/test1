#!/bin/bash

# Redirige les fichiers d'historique vers /dev/null
echo "Redirigeons l'historique des commandes vers /dev/null"

# Liste des fichiers d'historique à prendre en compte
files_to_redirect=(
  "/root/.bash_history"
  "/home/webvault/.bash_history"
  "/home/webvault/.mysql_history"
  "/home/webvault/.viminfo"
)

# Rediriger chaque fichier d'historique vers /dev/null
for file in "${files_to_redirect[@]}"; do
  if [ -f "$file" ]; then
    echo "Rediriger $file vers /dev/null"
    echo "" > "$file"
    chown root:root "$file"
    chmod 600 "$file"
  fi
done

# Assurer l'immuabilité des fichiers d'historique
echo "Assurer que les fichiers sont immuables"

for file in "${files_to_redirect[@]}"; do
  if [ -f "$file" ]; then
    chattr +i "$file"
  fi
done

echo "Historique redirigé et sécurisé. Les fichiers sont maintenant immuables."
