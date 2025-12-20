# Debian-Server.sh

**Author:** [PiercingXX](https://github.com/PiercingXX)  
**Repo:** <https://github.com/PiercingXX/debian-server>  
**License:** MIT

---

## Overview

`debian-server.sh` is a single-file Bash installer for Debian 13 (Trixie), designed to quickly set up a media and AI workstation. It includes:

- **Nginx reverse proxy**
- **Cloudflare tunnels**
- **NVIDIA 4080 drivers & CUDA 13.0**
- **Docker & Docker Compose**
- **Nextcloud (Docker stack)**
- **Ollama (local LLM runtime)**
- **Developer fonts**
- **Yazi (file manager) & Neovim**
- **Custom dotfiles & shell tweaks**
- **Firewall, upgrades, swap, etc.**

Interactive installation is guided via a whiptail menu. Non-interactive mode is available with `--no-menu`.

---

## Quick Start

```bash
sudo apt install git kitty -y
git clone https://github.com/PiercingXX/debian-server
chmod +x debian-server/debian-server.sh
cd debian-server
sudo ./debian-server.sh
```

---

## Environment

| Variable    | Default                | Purpose                |
|-------------|------------------------|------------------------|
| `USERNAME`  | `id -u -n 1000`        | Primary user           |
| `BUILD_DIR` | `pwd`                  | Working directory      |

---

## Usage

- **Interactive:** Run the script and follow the menu.
- **Non-interactive:**  
  ```bash
  ./debian-server.sh --no-menu
  ```
  *(Requires script modification to support this flag.)*

---

## Notes

- **NVIDIA GPU:** Required for CUDA and DaVinci Resolve.
- **Nextcloud:** Manual setup required after Docker install.
- **Ollama:**  
  ```
  ollama create skippy -f skippy.modelfile
  ```
- **Yazi:**  
  ```
  yazi
  ```
- **Neovim:**  
  ```
  vi
  ```
- **Dotfiles & Maintenance:**  
  ```
  xx
  ```

---

## License

MIT – see LICENSE.

---

## Contributing

Fork, hack, and PRs welcome.
