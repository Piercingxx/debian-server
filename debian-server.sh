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
    sudo apt install wget gpg -y 
    sudo apt install zip unzip gzip tar -y
    sudo apt install bash bash-completion -y
    sudo apt install tar bat tree multitail fastfetch fontconfig trash-cli -y
    sudo apt install build-essential -y
    sudo apt install make -y
    sudo apt install gettext -y
    sudo apt install gcc -y
    sudo apt install curl -y
    sudo apt install pipx -y
    sudo apt install nodejs -y
    sudo apt install fzf -y

# Firewall
    sudo apt install ufw -y
    sudo ufw allow OpenSSH
    sudo ufw allow 8080/tcp
    sudo ufw enable

# Ollama
    echo -e "${YELLOW}Installing Ollama…${NC}"
    curl -fsSL https://ollama.com/install.sh | sh
    sudo ufw allow 11434/tcp
    # ollama pull gpt-oss:120b
    # ollama pull skippy:latest
    # ollama pull gpt-oss:20b
    # ollama pull gemma3:latest
    # ollama pull gemma3n:latest

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

# Tailscale
    # The Tailscale install is now handled by the same compose.yaml as Nextcloud
    # Do not install Tailscale here to avoid conflicts
    # curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    # curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
    # sudo apt update -y
    # sudo apt install tailscale -y
    # sudo tailscale up

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
    sudo apt install luarocks -y
    sudo apt install python3-pip -y
    # Install Yazi
    # Ensure Rust is installed
    if ! command_exists cargo; then
        echo -e "${YELLOW}Installing Rust toolchain…${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # Load the new cargo environment for this shell
        source "$HOME/.cargo/env"
    fi
    # Verify cargo is now available
    if ! command_exists cargo; then
        echo -e "${RED}Cargo could not be found after installation. Aborting Yazi install.${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Installing Yazi via source build…${NC}"
    # Ensure Yazi's binary directory is in the PATH for this session
    export PATH="$HOME/.cargo/bin:$PATH"
    # Clone the Yazi repository (use the latest release tag)
    YAZI_REPO="https://github.com/sxyazi/yazi.git"
    YAZI_DIR="/tmp/yazi-build"
    git clone --depth 1 "$YAZI_REPO" "$YAZI_DIR" || { echo -e "${RED}Failed to clone Yazi repo.${NC}"; exit 1; }
    # Build the binary
    cd "$YAZI_DIR" || exit
    cargo build --release || { echo -e "${RED}Cargo build failed.${NC}"; exit 1; }
    # Install the binary
    sudo install -Dm755 target/release/yazi /usr/local/bin/yazi
    # Clean up
    cd "$BUILD_DIR" || exit
    rm -rf "$YAZI_DIR"

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
