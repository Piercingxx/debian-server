#!/usr/bin/env bash
# https://github.com/PiercingXX
# One‑file Debian bootstrap for a small‑business media & AI server
# ----------------------------------------------------------------
# Features:
#   • System update & upgrade
#   • NVIDIA 4080 driver stack
#   • Docker
#   • Nvim/Yazi/Starship/Zoxcide/FZF
#   • Ollama (local LLM)
#   • Piercing‑dots
# ----------------------------------------------------------------

set -euo pipefail

# Colors
YELLOW='\e[33m'
GREEN='\e[32m'
BLUE='\e[34m'
NC='\e[0m'

# Helper functions
command_exists() { command -v "$1" >/dev/null 2>&1; }

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
        "Nvidia Driver"     "Install Nvidia Drivers" \
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

# Bash Stuff
    install_bashrc_support

# Nginx
    sudo apt install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx

# Firewall
    sudo apt install fail2ban -y
    sudo apt install ufw -y
    sudo ufw allow OpenSSH
    sudo ufw allow SSH
    sudo ufw allow 8080/tcp
    sudo ufw allow 11434/tcp
    sudo ufw allow 10300/tcp
    sudo ufw allow 10400/tcp
    sudo ufw allow in on tailscale0
    sudo ufw allow in on tailscale0 to any port 11434 proto tcp
    sudo ufw allow 41641/udp   # Tailscale wire protocol
    sudo ufw enable

# Basic Updates
    sudo apt install unattended-upgrades -y
    
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
    # Stop and disable systemd Ollama service if running
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





# Docker
    echo -e "${YELLOW}Installing Docker Engine…${NC}"
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bookworm stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    sudo usermod -aG docker "$USERNAME"
    newgrp docker

# Docker create volumes and run n8n
# For production, set up HTTPS and remove N8N_SECURE_COOKIE=false.
    echo -e "${YELLOW}Creating Docker volumes and running n8n…${NC}"
    docker volume create n8n_data
    docker run -it --rm \
        --name n8n \
        -p 5678:5678 \
        -e GENERIC_TIMEZONE="<YOUR_TIMEZONE>" \
        -e TZ="<YOUR_TIMEZONE>" \
        -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
        -e N8N_RUNNERS_ENABLED=true \
        -e N8N_SECURE_COOKIE=false \
        -v n8n_data:/home/node/.n8n \
        docker.n8n.io/n8nio/n8n

# Tailscale
    curl -fsSL https://tailscale.com/install.sh | sh
#    sudo tailscale up
#    sudo systemctl enable --now tailscaled
#    sudo tailscale up --ssh --accept-routes

# OpenWebUI
docker run -d -p 8081:8080 -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://192.168.1.242:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
sudo ufw allow 8081/tcp


# Nextcloud
#   Setup Nextcloud via Docker after first boot
#   See: https://github.com/nextcloud/all-in-one/discussions/5439
#   Everything you need to get Nextcloud running inside your tailscale network is there.
#   Also check out Headscale for a self-hosted alternative to Tailscale.

# Nvidia
    echo "Installing Nvidia drivers and CUDA..."
    # Update package lists
    wget https://developer.download.nvidia.com/compute/cuda/13.0.0/local_installers/cuda-repo-debian12-13-0-local_13.0.0-580.65.06-1_amd64.deb
    sudo dpkg -i cuda-repo-debian12-13-0-local_13.0.0-580.65.06-1_amd64.deb
    sudo cp /var/cuda-repo-debian12-13-0-local/cuda-*-keyring.gpg /usr/share/keyrings/
    sudo apt update
    sudo apt install cuda-toolkit-13-0 -y
    # Clean up
    apt autoremove -y

# Starship & Zoxide
    install_starship
    install_zoxide

# Yazi & Neovim
    echo -e "${YELLOW}Installing Yazi (file‑manager) and Neovim…${NC}"
    # Install Neovim
    sudo apt install neovim -y
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

}

# Main
USERNAME=$(id -u -n 1000)
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
