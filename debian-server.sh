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
        "Nvidia Driver"     "Install Nvidia Drivers (Do not install on a Surface Device)" \
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

    # ---------- NVIDIA Drivers ----------
    echo -e "${YELLOW}Installing NVIDIA driver stack for RTX 4080…${NC}"
    sudo apt-get install -y nvidia-driver-535 nvidia-dkms-535 nvidia-settings nvidia-utils-535

    # ---------- DaVinci Resolve Dependencies ----------
    echo -e "${YELLOW}Installing Resolve dependencies…${NC}"
    sudo apt-get install -y \
        libssl3 libgomp1 \
        libx11-6 libxext6 libxfixes3 libxrender1 libxrandr2 libxinerama1 libxss1 libxcursor1 libxi6 libxcomposite1 libxdamage1 libxft2 \
        libgl1-mesa-glx libglu1-mesa libgl1-mesa-dri libgl1-mesa-dev \
        libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libswresample-dev

    # ---------- DaVinci Resolve Studio ----------
    RESOLVE_DEB="https://blackmagicdesign.com/support/downloads/resolve-studio-18.5.1-1_amd64.deb"
    echo -e "${YELLOW}Downloading DaVinci Resolve Studio…${NC}"
    wget -O /tmp/resolve-studio.deb "$RESOLVE_DEB"
    echo -e "${YELLOW}Installing DaVinci Resolve Studio…${NC}"
    sudo dpkg -i /tmp/resolve-studio.deb || sudo apt-get install -f -y
    rm /tmp/resolve-studio.deb

    # ---------- Optional XFCE Desktop ----------
    if [[ "$INSTALL_XFCE" == true ]]; then
        echo -e "${YELLOW}Installing XFCE desktop environment…${NC}"
        sudo apt-get install -y xfce4 xfce4-goodies
        sudo systemctl enable lightdm --now
    fi

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

    # ---------- Nextcloud ----------
    echo -e "${YELLOW}Setting up Nextcloud via Docker Compose…${NC}"
    NEXTCLOUD_DIR="$BUILD_DIR/nextcloud"
    mkdir -p "$NEXTCLOUD_DIR"
    cat > "$NEXTCLOUD_DIR/docker-compose.yml" <<'EOF'
version: '3'
services:
  db:
    image: mariadb:10.6
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_PASSWORD: nextcloud
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud
    volumes:
      - db:/var/lib/mysql
  app:
    image: nextcloud:27
    restart: always
    ports:
      - "8080:80"
    environment:
      MYSQL_PASSWORD: nextcloud
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud
      MYSQL_HOST: db
    volumes:
      - nextcloud:/var/www/html
      - nextcloud_data:/var/www/html/data
volumes:
  db:
  nextcloud:
  nextcloud_data:
EOF
    cd "$NEXTCLOUD_DIR" || exit
    docker compose up -d
    cd "$BUILD_DIR" || exit

    # ---------- Ollama ----------
    echo -e "${YELLOW}Installing Ollama…${NC}"
    curl -fsSL https://ollama.com/install.sh | sh
    # ollama pull codellama:latest
    # ollama pull gemma3:latest

    # ---------- Fonts ----------
    echo -e "${YELLOW}Installing common fonts…${NC}"
    sudo apt-get install -y fonts-noto fonts-noto-color-emoji fonts-fira-code

    # ---------- Yazi & Neovim ----------
    echo -e "${YELLOW}Installing Yazi (file‑manager) and Neovim…${NC}"
    # Install Neovim
    sudo apt install neovim -y
    sudo apt install lua5.4 -y
    sudo apt install luarocks -y
    sudo apt install python3-pip -y
    # Install Yazi via cargo (Rust package manager)
    # Ensure Rust is installed
    if ! command_exists cargo; then
        echo -e "${YELLOW}Installing Rust toolchain…${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    echo -e "${YELLOW}Installing Yazi via cargo…${NC}"
    cargo install yazi
    # Add Yazi to PATH for the current session
    export PATH="$HOME/.cargo/bin:$PATH"
    # Create symlink
    sudo ln -sf "$HOME/.cargo/bin/yazi" /usr/local/bin/yazi

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

    # ---------- Cockpit ----------
    echo -e "${YELLOW}Installing Cockpit web‑console…${NC}"
    sudo apt-get install -y cockpit
    sudo systemctl enable --now cockpit.socket

    echo -e "${GREEN}PiercingXX  Customizations & Cockpit Applied successfully!${NC}"
    msg_box "System will reboot now."
    sudo reboot
}

# ---------- Nvidia driver install (stand‑alone) ----------
install_nvidia_driver() {
    echo -e "${YELLOW}Installing NVIDIA drivers…${NC}"
    sudo apt install -y nvidia-driver-535 nvidia-dkms-535 nvidia-settings nvidia-utils-535
    # Install CUDA 13.0 toolkit
    CUDA_REPO_PKG="cuda-repo-debian13-13-0-local_13.0.0-580.65.06-1_amd64.deb"
    # Download the CUDA repository package
    wget https://developer.download.nvidia.com/compute/cuda/13.0.0/local_installers/${CUDA_REPO_PKG}
    # Install the package
    dpkg -i ${CUDA_REPO_PKG}
    # Copy the keyring for the CUDA repository
    cp /var/cuda-repo-debian13-13-0-local/cuda-*-keyring.gpg /usr/share/keyrings/
    # Update apt cache again and install the toolkit
    apt update
    apt install -y cuda-toolkit-13-0
    # Clean up
    rm -f ${CUDA_REPO_PKG}
    apt autoremove -y
    echo -e "${GREEN}NVIDIA Drivers installed successfully!${NC}"
    msg_box "Drivers installed. Reboot the system to apply changes."
    sudo reboot
}

# ---------- Main ----------
USERNAME=$(id -u -n 1000)
BUILD_DIR=$(pwd)
INSTALL_XFCE=false   # set to true if you want XFCE

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
        "Nvidia Driver")
            install_nvidia_driver
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