#!/usr/bin/env bash
# Debian 13 Server Bootstrap - Production Deployment
# Deploys: Nextcloud, OpenWebUI, Ollama, Stable Diffusion, Audiobookshelf
# https://github.com/PiercingXX

set -euo pipefail

# Colors
YELLOW='\e[33m'
GREEN='\e[32m'
BLUE='\e[34m'
RED='\e[31m'
NC='\e[0m'

# Config
DOMAIN="${DOMAIN:-hhamanagement.com}"
BUILD_DIR=$(pwd)

# Helper functions
command_exists() { command -v "$1" >/dev/null 2>&1; }

generate_password() {
    openssl rand -base64 32 | tr -d '=' | head -c 32
}

cache_sudo_credentials() {
    echo -e "${YELLOW}Caching sudo credentials…${NC}"
    sudo -v
    (while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &)
}

msg_box() { whiptail --msgbox "$1" 0 0 0; }

menu() {
    whiptail --backtitle "GitHub.com/PiercingXX" --title "Main Menu" \
        --menu "Run Options In Order:" 0 0 0 \
        "Install"           "Install PiercingXX Debian" \
        "Reboot System"     "Reboot the system" \
        "Exit"              "Exit the script" 3>&1 1>&2 2>&3
}

# Network check
check_network() {
    if command_exists nmcli; then
        state=$(nmcli -t -f STATE g)
        [[ "$state" == connected ]] || { echo "Network connectivity required."; exit 1; }
    else
        ip -4 addr show | grep -q "inet " || { echo "Network connectivity required."; exit 1; }
    fi
    ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 || { echo "Internet unreachable."; exit 1; }
}

install_starship() {
    if ! command_exists starship; then
        if ! curl -sS https://starship.rs/install.sh | sh; then
            print_colored "$RED" "Something went wrong during starship install!"
            exit 1
        fi
    else
        printf "Starship already installed\n"
    fi
}

install_zoxide() {
    if ! command_exists zoxide; then
        if ! curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
            print_colored "$RED" "Something went wrong during zoxide install!"
            exit 1
        fi
    else
        printf "Zoxide already installed\n"
    fi
}


# Core install
install_system() {
    echo -e "${YELLOW}Updating system packages…${NC}"
    sudo sed -i 's/main non-free-firmware/main contrib non-free non-free-firmware/g' /etc/apt/sources.list && cat /etc/apt/sources.list | grep -v '^#' | grep -v '^$'
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt dist-upgrade -y
    sudo apt autoremove -y
    sudo apt clean

# Depends
    sudo apt install wget gpg zip unzip gzip tar make curl gcc gettext build-essential -y
    sudo apt install pipx -y
    sudo apt install nodejs -y
    sudo apt install jq -y
    sudo apt install libssl-dev pkg-config -y
    sudo apt install libnotify-bin -y
    sudo apt install trash-cli -y
    sudo apt install sqlite3 -y
    sudo apt install tmux -y
    sudo apt install sshpass -y
    sudo apt install htop -y
    sudo apt install nvtop -y
    sudo apt install lnav -y
    sudo apt install smartmontools -y
    sudo apt install lsscsi -y
    sudo apt install sg3-utils -y
    sudo apt install ledmon -y
    sudo apt install lm-sensors -y
    sudo apt install bc -y

# Nginx
    sudo apt install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx

# PHP 8.4-FPM
    echo -e "${YELLOW}Installing PHP 8.4-FPM…${NC}"
    sudo apt install -y lsb-release ca-certificates apt-transport-https gnupg2
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
    curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-php.gpg
    sudo apt update
    sudo apt install -y php8.4-fpm php8.4-cli php8.4-common php8.4-mysql php8.4-zip php8.4-gd php8.4-mbstring php8.4-curl php8.4-xml php8.4-bcmath
    sudo systemctl start php8.4-fpm
    sudo systemctl enable php8.4-fpm

# Firewall
    #After setup, use UFW to lock down all these ports and restrict server to Tailscare and Cloudflare Tunnel.
    sudo apt install fail2ban -y
    sudo apt install ufw -y
    sudo ufw allow OpenSSH
    sudo ufw allow SSH
    sudo ufw allow 8080/tcp    # Nextcloud AIO Master
    sudo ufw allow 8443/tcp    # Nextcloud HTTPS
    sudo ufw allow 11000/tcp   # Nextcloud Apache
    sudo ufw allow 11434/tcp   # Ollama
    sudo ufw allow 8081/tcp    # OpenWebUI
    sudo ufw allow 7860/tcp    # Stable Diffusion
    sudo ufw allow 5678/tcp    # n8n
    sudo ufw allow 16678/tcp   # Audiobookshelf
    sudo ufw allow 10300/tcp   # Wyoming Whisper (STT)
    sudo ufw allow 10200/tcp   # Wyoming Piper (TTS)
    sudo ufw allow 3478/tcp    # Nextcloud Talk TURN
    sudo ufw allow 3478/udp    # Nextcloud Talk TURN
    sudo ufw allow 5804/tcp    # Container Management
    sudo ufw allow in on tailscale0
    sudo ufw allow in on tailscale0 to any port 11434 proto tcp
    sudo ufw allow 41641/udp   # Tailscale wire protocol
    sudo ufw enable

# Basic Updates
    sudo apt install unattended-upgrades -y

# ClamAV Antivirus
    echo -e "${YELLOW}Installing ClamAV antivirus…${NC}"
    sudo apt install -y clamav clamav-daemon clamav-freshclam
    sudo systemctl stop clamav-freshclam
    sudo freshclam
    sudo systemctl start clamav-freshclam
    sudo systemctl enable clamav-freshclam
    sudo systemctl start clamav-daemon
    sudo systemctl enable clamav-daemon
    
# Cron job to automate updates weekly
    UPDATE_SCRIPT="$HOME/.scripts/PiercingXX-Settings-Menu/update-system.sh"
    LOG_FILE="/var/log/auto-update.log"
    # Create log file
        sudo touch "$LOG_FILE"
        sudo chown $USER:$USER "$LOG_FILE"
    # Remove old cron job if exists
        crontab -l 2>/dev/null | grep -v "$UPDATE_SCRIPT" | crontab - 2>/dev/null || true
    # Add new cron job (Tuesday 3am)
        (crontab -l 2>/dev/null; echo "0 3 * * 2 $UPDATE_SCRIPT >> $LOG_FILE 2>&1") | crontab -
    echo "✓ Done! System will auto-update every Tuesday at 3am"

# Ollama
    echo -e "${YELLOW}Installing Ollama…${NC}"
    curl -fsSL https://ollama.com/install.sh | sh
    sudo ufw allow 11434/tcp
    # ollama pull gpt-oss:120b
    # ollama pull skippy:latest
    # ollama pull gpt-oss:20b
    # ollama pull gemma3:latest
    # ollama pull gemma3n:latest
    if systemctl list-units --type=service | grep -q "ollama.service"; then
        echo -e "${YELLOW}Stopping systemd Ollama service…${NC}"
        sudo systemctl stop ollama
        sudo systemctl disable ollama
    fi
    # Stop any process using port 11434 before starting Ollama
    while sudo lsof -i :11434 | grep LISTEN; do
        echo -e "${YELLOW}Killing process using port 11434…${NC}"
        sudo lsof -ti :11434 | xargs -r sudo kill -9
        sleep 1
    done
    # Start Ollama listening on all interfaces (0.0.0.0) at port 11434
    OLLAMA_HOST=0.0.0.0 OLLAMA_PORT=11434 ollama serve
    # Rewrite Ollama systemd service file for correct auto-restart and network binding
    cat <<EOF | sudo tee /etc/systemd/system/ollama.service > /dev/null
    [Unit]
    Description=Ollama Service
    After=network-online.target

    [Service]
    ExecStart=/usr/local/bin/ollama serve
    User=ollama
    Group=ollama
    Restart=always
    RestartSec=3
    Environment="PATH=/home/dr3k/.local/bin:/home/dr3k/.cargo/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/local/sbin:/usr/sbin:/sbin"
    Environment=OLLAMA_HOST=0.0.0.0
    Environment=OLLAMA_PORT=11434

    [Install]
    WantedBy=default.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable ollama
    sudo systemctl restart ollama

# Ollama Proxy (OpenAI-compatible API)
    echo -e "${YELLOW}Setting up Ollama Proxy for OpenAI compatibility…${NC}"
    # Install litellm as OpenAI-compatible proxy
    pipx install litellm
    # Create systemd service for ollama-proxy
    cat <<EOF | sudo tee /etc/systemd/system/ollama-proxy.service > /dev/null
[Unit]
Description=Ollama OpenAI-Compatible Proxy
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=$USER_HOME
Environment="PATH=$USER_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$USER_HOME/.local/bin/litellm --model ollama/llama2 --api_base http://localhost:11434
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable ollama-proxy
    sudo systemctl start ollama-proxy

# Unified Log Streamer Service
    echo -e "${YELLOW}Creating unified log streamer service…${NC}"
    mkdir -p "$USER_HOME/.scripts"
    cat <<'EOF' > "$USER_HOME/.scripts/unified-log-streamer.sh"
#!/usr/bin/env bash
# Unified Log Streaming Service
# Aggregates logs from multiple sources for centralized monitoring

LOG_DIR="/var/log/unified-logs"
sudo mkdir -p "$LOG_DIR"
sudo chown $USER:$USER "$LOG_DIR"

while true; do
    # Stream Docker container logs
    docker ps --format '{{.Names}}' | while read container; do
        docker logs --tail 10 "$container" 2>&1 | sed "s/^/[$container] /" >> "$LOG_DIR/docker.log" 2>&1
    done
    
    # Stream Ollama logs
    journalctl -u ollama -n 10 --no-pager 2>&1 | sed 's/^/[ollama] /' >> "$LOG_DIR/services.log" 2>&1
    
    # Stream Nginx logs
    tail -n 10 /var/log/nginx/access.log 2>&1 | sed 's/^/[nginx] /' >> "$LOG_DIR/nginx.log" 2>&1
    
    sleep 60
done
EOF
    chmod +x "$USER_HOME/.scripts/unified-log-streamer.sh"
    
    # Create systemd service
    cat <<EOF | sudo tee /etc/systemd/system/unified-log-streamer.service > /dev/null
[Unit]
Description=Unified Log Streaming Service
After=network.target docker.service

[Service]
Type=simple
User=$USERNAME
ExecStart=$USER_HOME/.scripts/unified-log-streamer.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable unified-log-streamer
    sudo systemctl start unified-log-streamer

# Nginx Reverse Proxy Configurations
    echo -e "${YELLOW}Creating Nginx reverse proxy configurations…${NC}"
    mkdir -p "$USER_HOME/nginx-configs"
    
    # OpenWebUI reverse proxy
    cat <<'EOF' | sudo tee /etc/nginx/sites-available/openwebui > /dev/null
server {
    listen 80;
    server_name openwebui.DOMAIN.COM;
    
    location / {
        proxy_pass http://localhost:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

    # Nextcloud reverse proxy
    cat <<'EOF' | sudo tee /etc/nginx/sites-available/nextcloud > /dev/null
server {
    listen 80;
    server_name nextcloud.DOMAIN.COM;
    
    location / {
        proxy_pass http://localhost:11000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_max_body_size 10G;
        proxy_request_buffering off;
    }
}
EOF

    # Stable Diffusion reverse proxy
    cat <<'EOF' | sudo tee /etc/nginx/sites-available/stablediffusion > /dev/null
server {
    listen 80;
    server_name sd.DOMAIN.COM;
    
    location / {
        proxy_pass http://localhost:7860;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

    # n8n reverse proxy
    cat <<'EOF' | sudo tee /etc/nginx/sites-available/n8n > /dev/null
server {
    listen 80;
    server_name n8n.DOMAIN.COM;
    
    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

    # Audiobookshelf reverse proxy
    cat <<'EOF' | sudo tee /etc/nginx/sites-available/audiobookshelf > /dev/null
server {
    listen 80;
    server_name audiobooks.DOMAIN.COM;
    
    location / {
        proxy_pass http://localhost:16678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

    echo -e "${BLUE}Nginx configs created in /etc/nginx/sites-available/${NC}"
    echo -e "${BLUE}To enable a site, run: sudo ln -s /etc/nginx/sites-available/<site> /etc/nginx/sites-enabled/${NC}"
    echo -e "${BLUE}Then reload nginx: sudo systemctl reload nginx${NC}"
    echo -e "${BLUE}Replace DOMAIN.COM with your actual domain in each config file${NC}"

# Docker
    echo -e "${YELLOW}Installing Docker Engine…${NC}"
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bookworm stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    sudo usermod -aG docker "$USERNAME"

# Docker Daemon Configuration
    echo -e "${YELLOW}Configuring Docker daemon…${NC}"
    sudo mkdir -p /etc/docker
    cat <<EOF | sudo tee /etc/docker/daemon.json > /dev/null
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
EOF
    sudo systemctl restart docker

# Cloudflare Tunnel
    echo -e "${YELLOW}Installing Cloudflare Tunnel (cloudflared)…${NC}"
    sudo mkdir -p --mode=0755 /usr/share/keyrings && curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null && echo "GPG key downloaded"
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list && echo "Repository added"
    sudo apt-get update && sudo apt-get install -y cloudflared && echo "Cloudflared installed from repository"

# Tailscale
    echo -e "${YELLOW}Installing Tailscale VPN…${NC}"
    curl -fsSL https://tailscale.com/install.sh | sh
    sudo systemctl enable --now tailscaled
    echo -e "${BLUE}Tailscale installed. Run manually to authenticate:${NC}"
    echo -e "${BLUE}  sudo tailscale up --ssh --accept-routes${NC}"

# Docker Compose Configurations
    echo -e "${YELLOW}Setting up Docker Compose configurations…${NC}"
    mkdir -p "$USER_HOME/.docker"
    mkdir -p "$USER_HOME/docker-data"

# Environment Variables Template
    cat <<'EOF' > "$USER_HOME/.env"
# Domain Configuration
DOMAIN=example.com
SUBDOMAIN_OPENWEBUI=openwebui
SUBDOMAIN_NEXTCLOUD=nextcloud
SUBDOMAIN_SD=sd
SUBDOMAIN_N8N=n8n
SUBDOMAIN_AUDIOBOOKSHELF=audiobooks

# Ollama Configuration
OLLAMA_BASE_URL=http://localhost:11434

# Nextcloud AIO
NEXTCLOUD_DATADIR=$USER_HOME/docker-data/nextcloud

# Passwords (CHANGE THESE!)
POSTGRES_PASSWORD=CHANGE_ME
REDIS_PASSWORD=CHANGE_ME

# Timezone
TZ=America/New_York
EOF
    chown "$USERNAME:$USERNAME" "$USER_HOME/.env"

# OpenWebUI - Docker Compose
    cat <<'EOF' > "$USER_HOME/.docker/docker-compose.openwebui.yml"
version: '3.8'

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: always
    ports:
      - "8081:8080"
    volumes:
      - open-webui:/app/backend/data
    environment:
      - OLLAMA_BASE_URL=${OLLAMA_BASE_URL:-http://host.docker.internal:11434}
    extra_hosts:
      - "host.docker.internal:host-gateway"

volumes:
  open-webui:
EOF

# Stable Diffusion WebUI
    cat <<'EOF' > "$USER_HOME/.docker/docker-compose.stablediffusion.yml"
version: '3.8'

services:
  stable-diffusion-webui:
    image: universonic/stable-diffusion-webui:latest
    container_name: stable-diffusion-webui
    restart: always
    ports:
      - "7860:7860"
    volumes:
      - $HOME/docker-data/stable-diffusion:/data
      - $HOME/docker-data/stable-diffusion/output:/output
    environment:
      - CLI_ARGS=--allow-code --enable-insecure-extension-access --api
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
EOF

# n8n Workflow Automation
    cat <<'EOF' > "$USER_HOME/.docker/docker-compose.n8n.yml"
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: always
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=CHANGE_ME
      - N8N_HOST=${SUBDOMAIN_N8N}.${DOMAIN}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${SUBDOMAIN_N8N}.${DOMAIN}/

volumes:
  n8n_data:
EOF

# Audiobookshelf
    cat <<'EOF' > "$USER_HOME/.docker/docker-compose.audiobookshelf.yml"
version: '3.8'

services:
  audiobookshelf:
    image: ghcr.io/advplyr/audiobookshelf:latest
    container_name: audiobookshelf
    restart: always
    ports:
      - "16678:80"
    volumes:
      - $HOME/docker-data/audiobookshelf/config:/config
      - $HOME/docker-data/audiobookshelf/metadata:/metadata
      - $HOME/docker-data/audiobookshelf/audiobooks:/audiobooks
      - $HOME/docker-data/audiobookshelf/podcasts:/podcasts
    environment:
      - TZ=${TZ:-America/New_York}
EOF

# Wyoming Voice Services (Whisper + Piper)
    cat <<'EOF' > "$USER_HOME/.docker/docker-compose.wyoming.yml"
version: '3.8'

services:
  wyoming-whisper:
    image: rhasspy/wyoming-whisper:latest
    container_name: wyoming-whisper
    restart: always
    ports:
      - "10300:10300"
    volumes:
      - whisper_data:/data
    command: --model base --language en

  wyoming-piper:
    image: rhasspy/wyoming-piper:latest
    container_name: wyoming-piper
    restart: always
    ports:
      - "10200:10200"
    volumes:
      - piper_data:/data
    command: --voice en_US-lessac-medium

volumes:
  whisper_data:
  piper_data:
EOF

# Nextcloud All-in-One
    echo -e "${YELLOW}Creating Nextcloud AIO configuration…${NC}"
    cat <<'EOF' > "$USER_HOME/.docker/docker-compose.nextcloud.yml"
version: '3.8'

services:
  nextcloud-aio-mastercontainer:
    image: nextcloud/all-in-one:latest
    container_name: nextcloud-aio-mastercontainer
    restart: always
    ports:
      - "8080:8080"
      - "8443:8443"
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - APACHE_PORT=11000
      - APACHE_IP_BINDING=0.0.0.0
      - NEXTCLOUD_DATADIR=${NEXTCLOUD_DATADIR}
      - NEXTCLOUD_MOUNT=/mnt/
      - NEXTCLOUD_UPLOAD_LIMIT=10G
      - NEXTCLOUD_MAX_TIME=3600
      - NEXTCLOUD_MEMORY_LIMIT=512M

volumes:
  nextcloud_aio_mastercontainer:

# Note: Nextcloud AIO will create additional containers automatically:
# - nextcloud-aio-apache (port 11000)
# - nextcloud-aio-nextcloud
# - nextcloud-aio-database
# - nextcloud-aio-redis
# - nextcloud-aio-collabora
# - nextcloud-aio-talk (ports 3478 TCP/UDP)
# - nextcloud-aio-talk-recording
# - nextcloud-aio-notify-push
# - nextcloud-aio-whiteboard
# - nextcloud-aio-fulltextsearch
# - nextcloud-aio-imaginary
# - nextcloud-aio-clamav
# - nextcloud-aio-local-ai
# Access the admin interface at https://<server-ip>:8443
EOF

# Start all services
    echo -e "${YELLOW}Starting Docker Compose services…${NC}"
    cd "$USER_HOME/.docker" || exit
    docker compose -f docker-compose.openwebui.yml up -d
    docker compose -f docker-compose.stablediffusion.yml up -d
    docker compose -f docker-compose.n8n.yml up -d
    docker compose -f docker-compose.audiobookshelf.yml up -d
    docker compose -f docker-compose.wyoming.yml up -d
    docker compose -f docker-compose.nextcloud.yml up -d
    cd "$BUILD_DIR" || exit

    echo -e "${GREEN}All Docker services started!${NC}"
    echo -e "${BLUE}Nextcloud AIO: https://<server-ip>:8443${NC}"
    echo -e "${BLUE}OpenWebUI: http://<server-ip>:8081${NC}"
    echo -e "${BLUE}Stable Diffusion: http://<server-ip>:7860${NC}"
    echo -e "${BLUE}n8n: http://<server-ip>:5678${NC}"
    echo -e "${BLUE}Audiobookshelf: http://<server-ip>:16678${NC}"

# Nvidia
    echo "Installing Nvidia drivers and CUDA..."
    # Update package lists
    wget https://developer.download.nvidia.com/compute/cuda/13.0.0/local_installers/cuda-repo-debian12-13-0-local_13.0.0-580.65.06-1_amd64.deb
    sudo dpkg -i cuda-repo-debian12-13-0-local_13.0.0-580.65.06-1_amd64.deb
    sudo cp /var/cuda-repo-debian12-13-0-local/cuda-*-keyring.gpg /usr/share/keyrings/
    sudo apt update
    sudo apt install cuda-toolkit-13-0 -y
    sudo apt install nvidia-driver-cuda -y
    # Clean up
    apt autoremove -y

# Starship & Zoxide
    install_starship
    install_zoxide

# Yazi & Neovim
    echo -e "${YELLOW}Installing Yazi (file‑manager) and Neovim…${NC}"
    # Install Neovim
# Nvim Nightly & Depends
    sudo apt install cmake ninja-build gettext unzip curl build-essential -y
    git clone https://github.com/neovim/neovim.git
    cd neovim || exit
    git checkout nightly
    make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=/usr/local/
    sudo make install
    cd "$BUILD_DIR" || exit
    rm -rf neovim
    # Ensure /usr/local/bin is on PATH for all users
    sudo tee /etc/profile.d/local-path.sh >/dev/null <<'EOF'
export PATH="/usr/local/bin:$PATH"
EOF
    sudo chmod 644 /etc/profile.d/local-path.sh
    sudo apt install lua5.4 -y
    sudo apt install python3-pip -y
    sudo apt install chafa -y
    sudo apt install ripgrep -y
# Install Yazi
    # Ensure Rust is installed
    if ! command_exists cargo; then
        echo -e "${YELLOW}Installing Rust toolchain…${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # Load the new cargo environment for this shell
        source "$HOME/.cargo/env"
    fi
    cargo install --force --git https://github.com/sxyazi/yazi.git yazi-build
    # Install plugins
    ya pkg add dedukun/bookmarks
    ya pkg add yazi-rs/plugins:mount
    ya pkg add dedukun/relative-motions
    ya pkg add yazi-rs/plugins:chmod
    ya pkg add yazi-rs/plugins:smart-enter
    ya pkg add AnirudhG07/rich-preview
    ya pkg add grappas/wl-clipboard
    ya pkg add Rolv-Apneseth/starship
    ya pkg add yazi-rs/plugins:full-border
    ya pkg add uhs-robert/recycle-bin
    ya pkg add yazi-rs/plugins:diff


# Fonts
    echo -e "${YELLOW}Installing font…${NC}"
    sudo apt install fonts-noto fonts-anonymous-pro fonts-firacode fonts-jetbrains-mono -y
    mkdir -p "/home/$USERNAME/.local/share/fonts"

# Piercing‑dots
    echo -e "${YELLOW}Cloning piercing‑dots repo…${NC}"
    rm -rf piercing-dots
    git clone --depth 1 https://github.com/Piercingxx/piercing-dots.git
    cd piercing-dots || exit
    echo -e "${YELLOW}Running piercing‑dots installer…${NC}"
    chmod u+x install.sh
    ./install.sh
    echo -e "${YELLOW}Replacing .bashrc with custom version…${NC}"
    cp -f resources/bash/.bashrc "/home/$USERNAME/.bashrc"
    source "/home/$USERNAME/.bashrc"
    cd "$BUILD_DIR" || exit
    rm -rf piercing-dots
    source ~/.bashrc

# Bash Stuff
    install_bashrc_support

}

# Main
USERNAME="${SUDO_USER:-$(whoami)}"
USER_HOME="/home/$USERNAME"
BUILD_DIR=$(pwd)

# Ensure whiptail is present
if ! command_exists whiptail; then
    echo -e "${YELLOW}Installing whiptail…${NC}"
    sudo apt install whiptail -y
fi

check_network
cache_sudo_credentials

while true; do
    clear
    echo -e "${GREEN}Welcome ${USERNAME}${NC}\n"
    choice=$(menu)
    case "$choice" in
        "Install")
            install_system
            ;;
        "Reboot System")
            echo -e "${YELLOW}Rebooting system in 3 seconds…${NC}"
            sleep 3
            sudo reboot
            ;;
        "Exit")
            clear
            echo -e "${BLUE}Thank You Handsome!${NC}"
            exit 0
            ;;
    esac
    read -p "Press [Enter] to continue…"
done
