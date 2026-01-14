# Services & Ports · at a glance

Everything the script brings online and where to reach it.
After you setup everything, use UFW to lock down all these ports and restrict it to Tailscare and Cloudflare Tunnel.

## Web entry points 🌐
| Service | Port(s) | Purpose | URL pattern |
| --- | --- | --- | --- |
| Nextcloud AIO admin | 8080 / 8443 | AIO control plane | https://SERVER_IP:8443 |
| Nextcloud app (Apache) | 11000 | Main UI | http://SERVER_IP:11000 |
| OpenWebUI | 8081 | LLM chat UI | http://SERVER_IP:8081 |
| Stable Diffusion | 7860 | Image gen UI | http://SERVER_IP:7860 |
| n8n | 5678 | Automation | http://SERVER_IP:5678 |
| Audiobookshelf | 16678 | Media server | http://SERVER_IP:16678 |
| Ollama API | 11434 | LLM API | http://SERVER_IP:11434 |
| Wyoming Whisper | 10300 | STT | tcp://SERVER_IP:10300 |
| Wyoming Piper | 10200 | TTS | tcp://SERVER_IP:10200 |
| Nextcloud Talk TURN | 3478/tcp+udp | TURN | (TURN) |
| AIO Container Mgmt | 5804 | AIO management | http://SERVER_IP:5804 |

## Compose stacks 🐳
- **nextcloud** · docker-compose.nextcloud.yml → spawns AIO + 19 service containers
- **openwebui** · docker-compose.openwebui.yml → chat UI for Ollama
- **stablediffusion** · docker-compose.stablediffusion.yml → GPU-ready SD WebUI
- **n8n** · docker-compose.n8n.yml → workflows (basic auth in file)
- **audiobookshelf** · docker-compose.audiobookshelf.yml → audiobooks/podcasts
- **wyoming** · docker-compose.wyoming.yml → Whisper + Piper

## Systemd units 🧩
- ollama.service
- ollama-proxy.service (OpenAI-compatible)
- unified-log-streamer.service
- cloudflared.service (after you install)
- php8.4-fpm.service
- nginx.service
- docker.service
- tailscaled.service
- clamav-daemon.service + clamav-freshclam.service
- fail2ban.service

## Control cheats 🎛️
```bash
# Compose lifecycle
cd ~/.docker
docker compose -f docker-compose.openwebui.yml up -d
docker compose -f docker-compose.openwebui.yml down

# All stacks
for f in docker-compose.*.yml; do docker compose -f "$f" up -d; done
for f in docker-compose.*.yml; do docker compose -f "$f" down; done

# Services
systemctl status ollama ollama-proxy unified-log-streamer cloudflared nginx php8.4-fpm docker tailscaled
```

## Health check quickie ✅
```bash
# Ports
for p in 8080 8443 11000 8081 7860 5678 16678 11434 10300 10200; do sudo lsof -i :$p -sTCP:LISTEN && echo "OK $p"; done

# Containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

## Notes 📝
- Nextcloud AIO controls its child containers; stop master to stop them.
- Stable Diffusion will download models on first run (big).
- Wyoming services are for Home Assistant voice; swap models/voices as you like.
- n8n password lives in docker-compose.n8n.yml; change before exposure.
