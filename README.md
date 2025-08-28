# **Debian‑Server.sh** – *The One‑File Bootstrap for the “Small‑Business Media & AI Server” (Because you’re too lazy to read the manual)*

> **Author**: [PiercingXX](https://github.com/PiercingXX)  
> **Repository**: <https://github.com/PiercingXX/debian-server>  
> **License**: MIT  

---

## 📦 Overview

`debian-server.sh` is a *single‑file Bash installer* that will transform a brand‑new Debian 13 (Trixie) box into a fully‑featured media & AI workstation in under an hour.  
It bundles everything you need to get your video, data, and AI projects off the ground, plus a few extra goodies for the “I‑can‑do‑everything‑in‑one‑script” crowd.

| Feature | Description |
|---------|-------------|
| **System update** | `apt‑get` upgrade, dist‑upgrade, autoremove – because you’re not going to keep a broken kernel. |
| **NVIDIA 4080 driver stack** | `nvidia-driver-535`, CUDA 13.0 – for those who want to do serious GPU‑heavy work. |
| **DaVinci Resolve Studio** | 18.5.1 (64‑bit) – the industry‑standard video editor that *actually* works on Linux. |
| **Docker & Docker‑Compose** | Latest stable releases – because containers are the future, and you’re not a dinosaur. |
| **Nextcloud** | Docker‑Compose stack (MariaDB + Nextcloud) – your own private cloud, no “data‑pocalypse” from the big guys. |
| **Ollama** | Local LLM runtime – because you’re not going to pay for a cloud‑based LLM. |
| **Fonts & UI** | Noto, Fira‑Code, optional XFCE desktop – because you want to look good while you work. |
| **Yazi & Neovim** | Modern file‑manager & editor – because you’re a developer, not a Windows user. |
| **Piercing‑dots** | Custom dotfiles & shell tweaks – because your shell should be as badass as you are. |
| **Cockpit** | Web‑based system console – because you want to manage your server from the comfort of a browser. |
| **Optional** | Firewall, unattended‑upgrades, swap, etc. – because you’re a *real* system admin. |

The script uses a **whiptail** menu to guide you through the installation steps.  
It can also be run non‑interactively by passing the `--no‑menu` flag (see *Advanced Usage*).

---


## 🚀 How to Use It (Because You’re Still Reading)

  

```bash

# Make the script executable
chmod +x debian-server.sh

# (Optional) Enable XFCE
export INSTALL_XFCE=true

# Run the installer
./debian-server.sh

```

The script will:

1. Verify network connectivity (so you don’t get stuck in a “no internet” loop).
2. Cache sudo credentials (because you’re not going to type your password 12 times).
3. Show the menu (whiptail, because you’re a *real* Linux user).
4. Execute the chosen action (and reboot if you chose “Install”).


After the **Install** option finishes, the system will reboot automatically.

---

## 🔧 Customization

### Optional XFCE Desktop

The script installs XFCE only if the variable `INSTALL_XFCE` is set to `true`.  
Edit the script before running:

```bash
# Inside debian-server.sh
INSTALL_XFCE=true   # set to true if you want XFCE
```

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `USERNAME` | `$(id -u -n 1000)` | The primary user (used for Docker group, dotfiles, etc.) |
| `BUILD_DIR` | `$(pwd)` | Working directory for temporary files |
| `INSTALL_XFCE` | `false` | Toggle XFCE installation |

You can also export these variables in your shell before running the script:

```bash
export INSTALL_XFCE=true
./debian-server.sh
```

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
| **Surface Devices**      | Skip the **Nvidia Driver** option | Surface kernels may conflict with proprietary drivers.    |
| **Multiple Hard Drives** | Edit `fstab` after installation   | Ensure data persists across reboots.                      |


---
## 🛠️ Super 1337 Advanced Usage

### Running the NVIDIA Driver Installer Separately

If you only need the driver stack (e.g., you already have Resolve installed):

```bash
./debian-server.sh
# Choose "Nvidia Driver" from the menu
```

### Docker Compose

The script creates a `nextcloud` directory under the build directory and starts the stack with:

```bash
docker compose up -d
```

You can later manage it manually:

```bash
cd /path/to/nextcloud
docker compose down
docker compose up -d
```

### Ollama

After installation, pull a model:

```bash
ollama pull codellama:latest
```

### Yazi & Neovim

Yazi is installed via Cargo. If you want to use it from the terminal:

```bash
yazi
```

Neovim is installed via `apt`. Launch it with:

```bash
nvim
```


---

## 📄 License

MIT License – see the LICENSE file.

---

## 📞 Support & Contact (Because PiercingXX Is a Busy Person)

*“Don’t bother me. I’ve got better things to do than explain why I didn't add a comment somewhere.”*


---

## 🤝 Contributing

If you have suggestions, fork, hack, PR – I’ll check it out when I’m not busy making my world a slightly less boring place.