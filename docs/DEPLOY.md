# ZigMDM deployment: TLS and reverse proxy

**Related documentation**

| Doc | Link |
|-----|------|
| Overview & API | [../README.md](../README.md) |
| Android agent | [../agent/README.md](../agent/README.md) |
| Mock agent | [../tools/README.md](../tools/README.md) |

ZigMDM listens on plain HTTP by default (`127.0.0.1:8787`). For production, terminate TLS on a reverse proxy and forward to the binary.

## Recommended layout

```
Internet / LAN clients
        │
        ▼
   Caddy or nginx (TLS :443)
        │
        ▼
   zig-mdm (127.0.0.1:8787)
        │
        ▼
   mdm.db + packages/
```

## Caddy (simplest TLS)

```caddy
mdm.example.com {
    encode gzip
    reverse_proxy 127.0.0.1:8787
}
```

## nginx

```nginx
server {
    listen 443 ssl http2;
    server_name mdm.example.com;
    ssl_certificate     /etc/letsencrypt/live/mdm.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mdm.example.com/privkey.pem;
    client_max_body_size 200m;
    location / {
        proxy_pass http://127.0.0.1:8787;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Android / agents

- Production: `https://mdm.example.com`
- Emulator lab: `http://10.0.2.2:8787`

## Firewall

- Public: `443/tcp` only
- Host: bind `8787` to `127.0.0.1`

## Backups

```bash
cp mdm.db "/backup/mdm-$(date +%F).db"
```

## Checklist

1. Dedicated user for `zig-mdm`
2. Valid TLS on proxy
3. Change default `admin` / `changeme`
4. Agents use HTTPS
5. Automated `mdm.db` backup
