# Hytale Server Docker

A Docker image for running a dedicated Hytale server.

## Quick Start

```bash
# Run (first time - interactive for authentication)
docker run -it --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/data \
  -v hytale-game:/opt/hytale/game \
  -v hytale-downloader:/opt/hytale/downloader \
  ghcr.io/augusdogus/hytale-server
```

Or build locally:

```bash
docker build -t hytale-server .
docker run -it --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/data \
  -v hytale-game:/opt/hytale/game \
  -v hytale-downloader:/opt/hytale/downloader \
  hytale-server
```

## First-Time Setup

You'll need to authenticate **twice**:

### 1. Downloader Authentication
On first run, you'll see:
```
Visit: https://accounts.hytale.com/device
Enter code: XXXX-XXXX
```
Complete this in your browser. The game files will download automatically.

### 2. Server Authentication
Once the server starts, run in the console:
```
/auth login device
```
Complete the device auth again, then **persist the credentials**:
```
/auth persistence Encrypted
```

Now you can detach (`Ctrl+P`, `Ctrl+Q`) and the server will stay authenticated across restarts.

## Running After Setup

```bash
# Start
docker start hytale-server

# Stop
docker stop hytale-server

# View logs
docker logs -f hytale-server

# Access console
docker attach hytale-server
# Detach: Ctrl+P, Ctrl+Q
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MEMORY` | Java heap size (min 4GB recommended) | `4G` |
| `SERVER_PORT` | UDP port | `5520` |
| `ENABLE_BACKUP` | Enable automatic backups | `false` |
| `BACKUP_INTERVAL` | Minutes between backups | `30` |
| `DISABLE_SENTRY` | Disable crash reporting | `false` |
| `AUTH_MODE` | `authenticated` or `offline` | `authenticated` |

Example with options:
```bash
docker run -it --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/data \
  -v hytale-game:/opt/hytale/game \
  -v hytale-downloader:/opt/hytale/downloader \
  -e MEMORY=6G \
  -e ENABLE_BACKUP=true \
  ghcr.io/augusdogus/hytale-server
```

## Firewall

Hytale uses **UDP** (not TCP):

```bash
# Ubuntu/Debian
sudo ufw allow 5520/udp

# Or iptables
sudo iptables -A INPUT -p udp --dport 5520 -j ACCEPT
```

## Docker Compose

```yaml
services:
  hytale:
    image: ghcr.io/augusdogus/hytale-server
    ports:
      - "5520:5520/udp"
    environment:
      MEMORY: "4G"
    volumes:
      - data:/data
      - game:/opt/hytale/game
      - downloader:/opt/hytale/downloader
    stdin_open: true
    tty: true
    restart: unless-stopped

volumes:
  data:
  game:
  downloader:
```

## Troubleshooting

**Players can't connect:**
1. Check firewall allows **UDP** port 5520
2. Ensure server is authenticated (`/auth status`)
3. Run `/auth persistence Encrypted` if credentials aren't persisting

**Re-authenticate downloader:**
```bash
docker run --rm -v hytale-downloader:/dl alpine rm -f /dl/.hytale-downloader-credentials.json
```

## License

Hytale and related assets are property of Hypixel Studios.
