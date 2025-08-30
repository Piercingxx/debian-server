#!/usr/bin/env bash
# https://github.com/PiercingXX
# One‑file Debian bootstrap for a small‑business media & AI server
# ----------------------------------------------------------------
# Features:
#   • System update & upgrade
#   • NVIDIA 4080 driver stack
#   • DaVinci Resolve Studio (with deps)
#   • Docker + Nextcloud (docker‑compose)
#   • Ollama (local LLM runtime)
#   • Customizations (piercing‑dots)
#   • Optional XFCE desktop
#   • Fonts, swap, firewall, unattended‑upgrades (optional)
#   • Cockpit web‑console
# ----------------------------------------------------------------

set -euo pipefail

# ---------- Colors ----------
YELLOW='\e[33m'
GREEN='\e[32m'
BLUE='\e[34m'
NC='\e[0m'

# ---------- Helper functions ----------
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

# ---------- Network check ----------
check_network() {
    if command_exists nmcli; then
        state=$(nmcli -t -f STATE g)
        [[ "$state" == connected ]] || { echo "Network connectivity required."; exit 1; }
    else
        ip -4 addr show | grep -q "inet " || { echo "Network connectivity required."; exit 1; }
    fi
    ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 || { echo "Internet unreachable."; exit 1; }
}

# ---------- Core install logic ----------
install_system() {
    echo -e "${YELLOW}Updating system packages…${NC}"
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get dist-upgrade -y
    sudo apt-get autoremove -y
    sudo apt-get clean

# Depends
    sudo apt install wget gpg -y 
    sudo apt install zip unzip gzip tar -y
    sudo apt install bash bash-completion -y
    sudo apt install tar bat tree multitail fastfetch fontconfig trash-cli -y
    sudo apt install build-essential -y
    sudo apt install make -y
    sudo apt install gettext -y
    sudo apt install gcc -y
    sudo apt install curl -y
    sudo apt install cargo -y
    sudo apt install pipx -y



    # ---------- Cockpit ----------
    echo -e "${YELLOW}Installing Cockpit web‑console…${NC}"
    sudo apt-get install -y cockpit
    sudo systemctl enable --now cockpit.socket

    # Firewall
    sudo apt install ufw -y
    sudo ufw allow OpenSSH
    sudo ufw allow 9090/tcp
    sudo ufw enable



    # ---------- Yazi & Neovim ----------
    echo -e "${YELLOW}Installing Yazi (file‑manager) and Neovim…${NC}"
    # Install Neovim
    sudo apt install neovim -y
    sudo apt install lua5.4 -y
    sudo apt install luarocks -y
    sudo apt install python3-pip -y
    # Install Yazi via cargo (Rust package manager)
    echo -e "${YELLOW}Installing Yazi via cargo…${NC}"
    cargo install yazi-fm yazi-cli
    # Add Yazi to PATH for the current session
    export PATH="$HOME/.cargo/bin:$PATH"
    # Create symlink
    sudo ln -sf "$HOME/.cargo/bin/yazi" /usr/local/bin/yazi


    # Nvidia
    echo "Installing Nvidia drivers and CUDA..."
    # Update package lists
    wget https://developer.download.nvidia.com/compute/cuda/13.0.0/local_installers/cuda-repo-debian12-13-0-local_13.0.0-580.65.06-1_amd64.deb
    sudo dpkg -i cuda-repo-debian12-13-0-local_13.0.0-580.65.06-1_amd64.deb
    sudo cp /var/cuda-repo-debian12-13-0-local/cuda-*-keyring.gpg /usr/share/keyrings/
    sudo apt-get update
    sudo apt-get -y install cuda-toolkit-13-0
    # Clean up
    apt autoremove -y

# Tailscale
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
    sudo apt-get update -y
    sudo apt-get install tailscale -y
    sudo tailscale up





    # ---------- Docker ----------
    echo -e "${YELLOW}Installing Docker Engine…${NC}"
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bookworm stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USERNAME"
    newgrp docker

#    # ---------- Nextcloud ----------
#    echo -e "${YELLOW}Setting up Nextcloud via Docker Compose…${NC}"
#    NEXTCLOUD_DIR="$HOME/nextcloud"
#    mkdir -p "$NEXTCLOUD_DIR"
#    cat > "$NEXTCLOUD_DIR/docker-compose.yml" <<'EOF'
#version: '3'
#services:
#  db:
#    image: mariadb:10.6
#    restart: always
#    environment:
#      MYSQL_ROOT_PASSWORD: root_password
#      MYSQL_PASSWORD: nextcloud
#      MYSQL_DATABASE: nextcloud
#      MYSQL_USER: nextcloud
#    volumes:
#      - db:/var/lib/mysql
#  app:
#    image: nextcloud:27
#    restart: always
#    ports:
#      - "8080:80"
#    environment:
#      MYSQL_PASSWORD: nextcloud
#      MYSQL_DATABASE: nextcloud
#      MYSQL_USER: nextcloud
#      MYSQL_HOST: db
#    volumes:
#      - nextcloud:/var/www/html
#      - nextcloud_data:/var/www/html/data
#volumes:
#  db:
#  nextcloud:
#  nextcloud_data:
#EOF
#    cd "$NEXTCLOUD_DIR" || exit
#    docker compose up -d
#    cd "$BUILD_DIR" || exit

    # ---------- Ollama ----------
    echo -e "${YELLOW}Installing Ollama…${NC}"
    curl -fsSL https://ollama.com/install.sh | sh
    # ollama pull codellama:latest
    # ollama pull gemma3:latest

    # ---------- Fonts ----------
    echo -e "${YELLOW}Installing common fonts…${NC}"
    sudo apt-get install -y fonts-noto fonts-noto-color-emoji fonts-fira-code


    # ---------- Piercing‑dots ----------
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
}

# ---------- Main ----------
USERNAME=$(id -u -n 1000)
BUILD_DIR=$(pwd)

# Ensure whiptail is present
if ! command_exists whiptail; then
    echo -e "${YELLOW}Installing whiptail…${NC}"
    sudo apt-get install -y whiptail
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