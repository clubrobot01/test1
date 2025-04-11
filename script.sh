#!/bin/bash

# Install required packages
apt update
apt install -y nginx python3 python3-pip cron sudo

# Create vulnerable Flask app directory
mkdir -p /opt/vault-lite
cat << EOF > /opt/vault-lite/app.py
from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)

@app.route("/api/test", methods=["POST"])
def test():
    data = request.get_json()
    cmd = data.get("cmd")
    try:
        output = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
        return jsonify({"output": output.decode()})
    except subprocess.CalledProcessError as e:
        return jsonify({"error": e.output.decode()}), 400

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

# Install Flask
pip3 install flask

# Create systemd service for the Flask app
cat << EOF > /etc/systemd/system/vault-lite.service
[Unit]
Description=Vault Lite Flask API
After=network.target

[Service]
User=webvault
WorkingDirectory=/opt/vault-lite
ExecStart=/usr/bin/python3 /opt/vault-lite/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable vault-lite
systemctl start vault-lite

# Setup backup script
mkdir -p /backup
mkdir -p /opt/scripts
cat << EOF > /opt/scripts/backup.sh
#!/bin/bash
tar -czf /backup/$(date +%F).tar.gz \$BACKUP_DIR
EOF
chmod +x /opt/scripts/backup.sh

# Add cron job
echo "*/5 * * * * root /opt/scripts/backup.sh" >> /etc/crontab

# Add sudoers rule
echo "webvault ALL=(ALL) NOPASSWD: /bin/tar" > /etc/sudoers.d/webvault
chmod 440 /etc/sudoers.d/webvault
