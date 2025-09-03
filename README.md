# **Debian‑Server.sh** – *The One‑File Bootstrap for the “Small‑Business Media & AI Server”*

> **Author**: [PiercingXX](https://github.com/PiercingXX)  
> **Repository**: <https://github.com/PiercingXX/debian-server>  
> **License**: MIT  

---

## 📦 Overview

`debian-server.sh` is a *single‑file Bash installer* that will setup a brand‑new Debian 13 (Trixie) box into a fully‑featured media & AI workstation.  
It bundles everything you need to get your video, data, and AI projects off the ground, plus a few extra goodies for the “I‑can‑do‑everything‑in‑one‑script” crowd.

| Feature | Description |
|---------|-------------|
| **NVIDIA 4080 driver stack** | `nvidia-driver-535`, CUDA 13.0 – for those who want to do serious GPU‑heavy work. |
| **DaVinci Resolve Studio** | 18.5.1 (64‑bit) – the industry‑standard video editor that *actually* works on Linux. |
| **Docker & Docker‑Compose** | Latest stable releases – containers are the future, and you’re not a dinosaur. |
| **Nextcloud** | Docker‑Compose stack (MariaDB + Nextcloud) – your own private cloud, no “data‑pocalypse” from the big guys. |
| **Ollama** | Local LLM runtime – you’re not going to pay for a cloud‑based LLM. |
| **Fonts as UI** | noto, anonymous-pro, firacode, jetbrains-mono – if you only see font as your UI you want options. |
| **Yazi & Neovim** | Modern file‑manager & editor – you’re a developer, not a Windows user. |
| **Piercing‑dots** | Custom dotfiles & shell tweaks – your shell should be as badass as you are. |
| **Additional** | Firewall, unattended‑upgrades, swap, etc. – cronjob is also valid. |

The script uses a **whiptail** menu to guide you through the installation steps.  
It can also be run non‑interactively by passing the `--no‑menu` flag (see *Advanced Usage*).

---


## 🚀 How to Use It (Because You’re Still Reading)


```bash

sudo apt install git kitty -y

git clone https://github.com/PiercingXX/Debian-Server

chmod -R u+x debian-server

cd debian-server

sudo ./debian-server.sh

```

The script will:

1. Verify network connectivity.
2. Cache sudo credentials (because you’re not going to type your password 12 times).
3. Show the menu (whiptail, because you’re a *real* Linux user).

After the **Install** option finishes, the system will reboot automatically.

---

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `USERNAME` | `$(id -u -n 1000)` | The primary user (used for Docker group, dotfiles, etc.) |
| `BUILD_DIR` | `$(pwd)` | Working directory for temporary files |

You can also export these variables in your shell before running the script:

### Non‑Interactive Mode

If you prefer to skip the menu and run the full install automatically:

```bash
./debian-server.sh --no-menu
```

> **Note**: The script currently does not support `--no-menu` out of the box.  
> To add this feature, modify the `while` loop to check for the flag and call `install_system` directly.

---

## 🔌 Hardware‑Specific Notes (Because You’re a Hardware Connoisseur)


| Component                | Recommendation                    | Why                                                       |
| ------------------------ | --------------------------------- | --------------------------------------------------------- |
| **NVIDIA GPU**           | If you have Nvidia Hardware       | Provides CUDA 13.0 and driver stack for Resolve & Ollama. |


---
## 🛠️ Super 1337 Advanced Usage

### Running the NVIDIA Driver Installer Separately

If you only need the driver stack:

```bash
./debian-server.sh
# Choose "Nvidia Driver" from the menu
```

### Docker Compose

This script *only* installs Docker, I have removed the automation of Nextcloud because you *must* first setup the integration with whiptail.

### Ollama

After installation, pull a model:

```bash
ollama pull skyppy:latest
```

### Yazi & Neovim

Yazi is installed via Cargo. To use it from the terminal:

```bash
yazi
```

Neovim is installed via `apt`. Launch it with:

```bash
vi
```

### Piercing Dots

On Gnome and Hyprland systems the entire script makes more sense however I just dump my dot files in here because I'm lazy. I will edit this down at some point, the .bashrc and the Maintenance.sh are the highlight of the show here.
The .bashrc has all my shortcuts.
Maintenance.sh will auto update everything including itself. You can even set it to a cron job to have it run auto-magically at whatever interval you wish.
To use it from the terminal:

```bash
xx
```

---

## 📄 License

MIT License – see the LICENSE file.

---

## 📞 Support & Contact (Because PiercingXX Is a Busy Person)

*“Don’t. I’ve got better things to do than explain why I didn't add a comment somewhere.”*


---

## 🤝 Contributing

If you have suggestions, fork, hack, PR – I’ll check it out when I’m not busy making my world a slightly less boring place.
