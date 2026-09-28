# Local models (Ollama) — side tool

Not the MDM. Parent desk tab `/ai`. Students do not get this URL on SchoolDay.

## On tank

```bash
curl -fsSL https://ollama.com/install.sh | sh
sudo mkdir -p /etc/systemd/system/ollama.service.d
printf '%s\n' '[Service]' 'Environment=OLLAMA_HOST=0.0.0.0:11434' | sudo tee /etc/systemd/system/ollama.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl enable --now ollama
sudo ufw allow from 192.168.0.0/16 to any port 11434 proto tcp
```

Default Ollama is localhost only. The override is what lets the laptop desk talk to tank.

## What to pull on this class of box

Dell XPS-class i7 desktop, 16 GB RAM typical:

| RAM / GPU | Pull |
|-----------|------|
| 8 GB, iGPU | `ollama pull qwen2.5:1.5b` or `llama3.2:1b` |
| 16 GB, iGPU | `ollama pull qwen2.5:7b` or `llama3.2:3b` |
| 32 GB or 8 GB+ NVIDIA | `ollama pull qwen2.5:14b` or `llama3.1:8b` |
| Do not | 70B on this box |

```bash
ollama list
curl -sS http://127.0.0.1:11434/api/tags
```

The `/ai` page lists **whatever is installed**. Empty list = Ollama down or no models yet.

## CORS

If the desk can open tank:8787 but chat fails, set:

```
Environment=OLLAMA_ORIGINS=http://192.168.50.143:8787,http://learn.home:8787
```

in the same drop-in, then `systemctl restart ollama`.

Do not publish 11434 on the router.
