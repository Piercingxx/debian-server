# Debian Server · Press button, get stack

Headless Debian 13 build that turns a fresh VM into a self-hosting workhorse: Nextcloud AIO, Ollama + OpenWebUI, Stable Diffusion, n8n, Audiobookshelf, Wyoming voice, Cloudflare Tunnel, Tailscale, Nginx, Docker/Compose, PHP 8.4-FPM, ClamAV, log streaming. Menu-driven, opinionated, reproducible.

## What you get 🧰
- **Core**: Debian 13, UFW + fail2ban, unattended-upgrades, nginx, php8.4-fpm, docker w/ nvidia-runtime, tailscale, cloudflared, clamav, unified log streamer
- **AI**: Ollama API (11434), OpenWebUI (8081), Stable Diffusion WebUI (7860), Wyoming Whisper (10300) + Piper (10200), Ollama proxy (OpenAI-compatible)
- **Apps**: Nextcloud AIO (8080/8443, Apache 11000, Talk 3478), n8n (5678), Audiobookshelf (16678)
- **Dev/CLI**: Neovim nightly, Rust, Node.js, Python3, Lua 5.4, Starship, Zoxide, Yazi, tmux, jq, htop/nvtop/lnav, sqlite3, fonts

## Run it 🚀
```bash
git clone https://github.com/PiercingXX/debian-server.git
cd debian-server
chmod +x debian-server.sh
./debian-server.sh  # choose "Install"
```

## After install (critical) 🔑
1) Edit ~/.env (domain, subdomains, CHANGE_ME passwords, TZ, NEXTCLOUD_DATADIR)
2) Auth Tailscale: sudo tailscale up --ssh --accept-routes
3) Swap domains in nginx: sudo sed -i 's/DOMAIN.COM/yourdomain.com/g' /etc/nginx/sites-available/* then enable/reload
4) Start stacks (if not already):
```bash
cd ~/.docker
for f in docker-compose.*.yml; do docker compose -f "$f" up -d; done
```
5) Nextcloud AIO: https://SERVER_IP:8443 → finish wizard, set domain/SSL
6) Pull Ollama models (examples):
```bash
ollama pull llama2
ollama pull codellama
ollama pull mistral
ollama pull mixtral
```

## Ports & access 🌐
- Nextcloud AIO: 8080/8443 admin, Apache 11000
- OpenWebUI: 8081
- Stable Diffusion: 7860
- n8n: 5678
- Audiobookshelf: 16678
- Ollama: 11434
- Wyoming: 10300 (Whisper), 10200 (Piper)
- Nextcloud Talk TURN: 3478 TCP/UDP
- Container mgmt: 5804
- All mirrored through nginx + optional Cloudflare Tunnel

## Service stack (Compose) 🐳
- docker-compose.nextcloud.yml → Nextcloud AIO (spawns 19+ containers)
- docker-compose.openwebui.yml → OpenWebUI
- docker-compose.stablediffusion.yml → Stable Diffusion (GPU-ready)
- docker-compose.n8n.yml → n8n with basic auth
- docker-compose.audiobookshelf.yml → Audiobookshelf
- docker-compose.wyoming.yml → Whisper + Piper

Systemd extras: ollama.service, ollama-proxy.service, cloudflared.service (after you install), unified-log-streamer.service, php8.4-fpm.service, tailscaled.service, clamav-*, nginx, docker.

## Ops cheats 📋
```bash
# Services
systemctl status ollama ollama-proxy nginx php8.4-fpm docker tailscaled clamav-daemon

# Compose (per service)
cd ~/.docker
docker compose -f docker-compose.openwebui.yml up -d

# Logs
journalctl -u ollama -n 50
sudo tail -f /var/log/unified-logs/docker.log

docker compose -f docker-compose.openwebui.yml logs -f

docker ps
```

## Security notes 🔒
- Update all CHANGE_ME in ~/.env and compose files.
- Prefer Tailscale or Cloudflare Tunnel over raw port exposure.
- UFW rules pre-open the service ports listed above.

## Data locations 🗂️
- Compose configs: ~/.docker/*.yml
- Persistent data: ~/docker-data/...
- Nginx sites: /etc/nginx/sites-available/
- Scripts: ~/.scripts/
- Logs: /var/log/unified-logs/

## Troubleshooting 🛠️
- Containers: docker ps, docker logs <name>
- Ports: sudo lsof -i :<port>
- Nginx: sudo nginx -t, sudo tail -f /var/log/nginx/error.log
- GPU in containers: docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

## Optional: Cloudflare Tunnel 🌩️
```bash
cloudflared tunnel login
cloudflared tunnel create my-server
nano ~/.cloudflared/config.yml   # map domains → localhost ports
sudo cloudflared service install
sudo systemctl start cloudflared
```

## Optional: Backup sketch 📦
```bash
BACKUP_DIR="/backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/docker-data.tar.gz" ~/docker-data/
tar -czf "$BACKUP_DIR/configs.tar.gz" ~/.docker/ ~/.env ~/.scripts/ /etc/nginx/sites-available/
```

## Philosophy 🌀
Press button, watch the chaos organize itself. Reproducible, opinionated, bash-first. If you like frictionless servers, this is as close as it gets.

