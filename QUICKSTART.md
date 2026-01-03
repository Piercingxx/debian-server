# Quick Start · from ISO to stack

90% of the work in ~30-60 minutes.

## 0) Prereqs
- Fresh Debian 13 (Trixie)
- sudo user
- Internet
- (Optional) NVIDIA GPU

## 1) Install
```bash
git clone https://github.com/PiercingXX/debian-server.git
cd debian-server
chmod +x debian-server.sh
./debian-server.sh  # choose "Install"
```

## 2) Must-do right after
1) Edit ~/.env → domain, subdomains, CHANGE_ME passwords, TZ, NEXTCLOUD_DATADIR
2) Tailscale auth → sudo tailscale up --ssh --accept-routes
3) Swap domains in nginx → sudo sed -i 's/DOMAIN.COM/yourdomain.com/g' /etc/nginx/sites-available/* && sudo systemctl reload nginx
4) Bring up stacks (if not already):
```bash
cd ~/.docker
for f in docker-compose.*.yml; do docker compose -f "$f" up -d; done
```
5) Finish Nextcloud AIO at https://SERVER_IP:8443 (set domain/SSL, save admin pass)
6) Pull Ollama models (pick a few):
```bash
ollama pull llama2
ollama pull codellama
ollama pull mistral
ollama pull mixtral
```

## 3) First login URLs (swap SERVER_IP)
- Nextcloud AIO admin: https://SERVER_IP:8443
- Nextcloud app: http://SERVER_IP:11000
- OpenWebUI: http://SERVER_IP:8081
- Stable Diffusion: http://SERVER_IP:7860
- n8n: http://SERVER_IP:5678 (basic auth in compose file)
- Audiobookshelf: http://SERVER_IP:16678

## 4) Ops cheats
```bash
# Services
systemctl status ollama ollama-proxy nginx php8.4-fpm docker tailscaled

# Containers
docker ps

# Logs
docker logs -f open-webui
journalctl -u ollama -n 50
```

## 5) Optional externals
- **Cloudflare Tunnel**: cloudflared tunnel login → create → map domains → service install
- **Tailscale only**: use tailnet IPs; no domains needed

## 6) If something is weird
- Port blocked? sudo lsof -i :<port>
- Ollama? systemctl status ollama; curl http://localhost:11434/api/tags
- Nextcloud? docker logs nextcloud-aio-mastercontainer
- GPU in containers? docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

## 7) Next moves
- Add media to Audiobookshelf (~/docker-data/audiobookshelf)
- Wire automations in n8n
- Enable optional Nextcloud AIO components
- Set backups (see README backup sketch)

You now own the stack. 🚀
