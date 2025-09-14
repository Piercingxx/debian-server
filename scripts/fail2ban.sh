#!/bin/bash

# Fail2ban install and setup script for Debian-based systems
# Includes basic jail configuration for Nextcloud, Ollama, n8n, Audiobookshelf, and SSH

set -e

echo "Installing Fail2ban..."
sudo apt update
sudo apt install -y fail2ban

echo "Configuring Fail2ban..."

# Create local jail configuration
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = auto
destemail = root@localhost
sendername = Fail2Ban
mta = sendmail
action = %(action_mwl)s

[sshd]
enabled = true

[nextcloud]
enabled = true
port = http,https
filter = nextcloud
logpath = /mnt/docker-aio-config/nextcloud/data/nextcloud.log
maxretry = 5

[ollama]
enabled = true
port = 8081
filter = ollama
logpath = /var/lib/docker/volumes/ollama_logs/_data/ollama.log
maxretry = 5

[n8n]
enabled = true
port = 5678
filter = n8n
logpath = /var/lib/docker/volumes/n8n_data/_data/n8n.log
maxretry = 5

[audiobookshelf]
enabled = true
port = 13378
filter = audiobookshelf
logpath = /var/lib/docker/volumes/audiobookshelf_data/_data/audiobookshelf.log
maxretry = 5
EOF

# Create filter files for each service
sudo mkdir -p /etc/fail2ban/filter.d

# Nextcloud filter
sudo tee /etc/fail2ban/filter.d/nextcloud.conf > /dev/null <<'EOF'
[Definition]
failregex = Login failed: .* Remote IP: '<HOST>'
ignoreregex =
EOF

# Ollama filter (example, adjust as needed)
sudo tee /etc/fail2ban/filter.d/ollama.conf > /dev/null <<'EOF'
[Definition]
failregex = Unauthorized access attempt from <HOST>
ignoreregex =
EOF

# n8n filter (example, adjust as needed)
sudo tee /etc/fail2ban/filter.d/n8n.conf > /dev/null <<'EOF'
[Definition]
failregex = Authentication failed for user .* from <HOST>
ignoreregex =
EOF

# Audiobookshelf filter (example, adjust as needed)
sudo tee /etc/fail2ban/filter.d/audiobookshelf.conf > /dev/null <<'EOF'
[Definition]
failregex = Failed login attempt from <HOST>
ignoreregex =
EOF

echo "Restarting Fail2ban..."
sudo systemctl restart fail2ban

echo "Fail2ban setup complete. Status:"
sudo fail2ban-client status