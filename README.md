# Hytale Server Docker

A Docker image for running a dedicated Hytale server, with configuration style inspired by [itzg/minecraft-server](https://github.com/itzg/docker-minecraft-server).

## Quick Start

```bash
docker compose up -d
```

On first run, authenticate interactively:

```bash
docker compose run -it hytale
```

Follow the prompts to authenticate at `https://accounts.hytale.com/device`.

## Important Differences from Minecraft

| Feature | Minecraft (itzg) | Hytale |
|---------|------------------|--------|
| Protocol | TCP | **UDP (QUIC)** |
| Default Port | 25565 | **5520** |
| Min RAM | 1GB | **4GB** |
| View Distance | 10 chunks (160 blocks) | 12 chunks (384 blocks) ≈ 24 MC chunks |
| RCON | Built-in | Not available |
| Config | server.properties | **JSON files** |

## Environment Variables

### General Options

| Variable | Description | Default |
|----------|-------------|---------|
| `UID` | Linux user ID | `1000` |
| `GID` | Linux group ID | `1000` |
| `MEMORY` | Java heap size | `4G` |
| `INIT_MEMORY` | Initial heap (overrides MEMORY) | |
| `MAX_MEMORY` | Max heap (overrides MEMORY) | |
| `TZ` | Timezone | `UTC` |
| `JVM_OPTS` | Additional JVM options | |
| `JVM_XX_OPTS` | JVM -XX options | |

### Download Options

| Variable | Description | Default |
|----------|-------------|---------|
| `AUTO_DOWNLOAD` | Download server files automatically | `true` |
| `PATCHLINE` | `release` or `pre-release` | `release` |
| `SETUP_ONLY` | Download only, don't start server | `false` |

### Server Options

These map directly to Hytale server arguments:

| Variable | Server Flag | Description | Default |
|----------|-------------|-------------|---------|
| `SERVER_PORT` | `--bind` | UDP port | `5520` |
| `AUTH_MODE` | `--auth-mode` | `authenticated` or `offline` | `authenticated` |
| `ALLOW_OP` | `--allow-op` | Enable operator commands | `false` |
| `ENABLE_BACKUP` | `--backup` | Enable automatic backups | `false` |
| `BACKUP_INTERVAL` | `--backup-frequency` | Minutes between backups | `30` |
| `DISABLE_SENTRY` | `--disable-sentry` | Disable crash reporting | `false` |
| `ACCEPT_EARLY_PLUGINS` | `--accept-early-plugins` | Allow experimental plugins | `false` |
| `EXTRA_ARGS` | | Additional server arguments | |

## Configuration Files

Unlike Minecraft's `server.properties`, Hytale uses **JSON files** for configuration. These are created by the server on first run:

| File | Description |
|------|-------------|
| `config.json` | Server configuration |
| `permissions.json` | Permission configuration |
| `whitelist.json` | Whitelisted players |
| `bans.json` | Banned players |

To customize, mount your own files:

```yaml
volumes:
  - ./whitelist.json:/data/whitelist.json
  - ./permissions.json:/data/permissions.json
```

## Examples

### Basic Server

```yaml
services:
  hytale:
    image: hytale-server
    ports:
      - "5520:5520/udp"
    environment:
      MEMORY: "4G"
    volumes:
      - data:/data
volumes:
  data:
```

### Development Server

```yaml
services:
  hytale:
    image: hytale-server
    ports:
      - "5520:5520/udp"
    environment:
      MEMORY: "4G"
      DISABLE_SENTRY: "true"        # Don't report dev crashes
      ACCEPT_EARLY_PLUGINS: "true"  # Allow experimental plugins
      PATCHLINE: "pre-release"      # Use pre-release builds
    volumes:
      - data:/data
      - ./mods:/data/mods           # Mount local mods folder
volumes:
  data:
```

### Server with Backups

```yaml
services:
  hytale:
    image: hytale-server
    ports:
      - "5520:5520/udp"
    environment:
      MEMORY: "6G"
      ENABLE_BACKUP: "true"
      BACKUP_INTERVAL: "30"  # Every 30 minutes
    volumes:
      - data:/data
volumes:
  data:
```

### Offline Mode (No Authentication)

```yaml
services:
  hytale:
    image: hytale-server
    ports:
      - "5520:5520/udp"
    environment:
      MEMORY: "4G"
      AUTH_MODE: "offline"
    volumes:
      - data:/data
volumes:
  data:
```

## Memory Recommendations

Hytale requires **at least 4GB RAM**. The default view distance (384 blocks / 12 chunks) is equivalent to ~24 Minecraft chunks, so expect higher memory usage than Minecraft.

| Use Case | Recommended |
|----------|-------------|
| Testing / Development | 4GB |
| Small server (1-5 players) | 4-6GB |
| Medium server (5-20 players) | 6-8GB |
| Large server (20+ players) | 8GB+ |

## Volumes

| Volume | Path | Description |
|--------|------|-------------|
| `data` | `/data` | Server data (universe, mods, logs, configs) |
| `game` | `/opt/hytale/game` | Downloaded game files |
| `downloader` | `/opt/hytale/downloader` | OAuth credentials |

### Data Directory Structure

```
/data/
├── universe/       # World saves
├── mods/           # Installed mods
├── logs/           # Server logs
├── backups/        # Automatic backups (if enabled)
├── .cache/         # Optimized file cache
├── config.json     # Server configuration
├── permissions.json
├── whitelist.json
└── bans.json
```

## Sending Commands

Hytale doesn't have RCON. Use `docker attach` to access the console:

```bash
# Attach to console
docker attach hytale-server

# Type commands
/help

# Detach WITHOUT stopping: Ctrl+P, Ctrl+Q
```

## Firewall Configuration

**Hytale uses UDP, not TCP!**

```bash
# UFW (Ubuntu)
sudo ufw allow 5520/udp

# iptables
sudo iptables -A INPUT -p udp --dport 5520 -j ACCEPT

# Windows PowerShell
New-NetFirewallRule -DisplayName "Hytale Server" -Direction Inbound -Protocol UDP -LocalPort 5520 -Action Allow
```

## Installing Mods

Download mods from [CurseForge](https://www.curseforge.com/hytale) and place in the mods directory:

```bash
# Mount host directory
volumes:
  - ./mods:/data/mods

# Or copy into container
docker cp my-mod.jar hytale-server:/data/mods/
```

## Recommended Plugins

From the [Hytale Server Manual](https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual):

| Plugin | Description |
|--------|-------------|
| [Nitrado:Query](https://github.com/nitrado/hytale-plugin-query) | Server status via HTTP |
| [Nitrado:PerformanceSaver](https://github.com/nitrado/hytale-plugin-performance-saver) | Dynamic view distance |
| [ApexHosting:PrometheusExporter](https://github.com/apexhosting/hytale-plugin-prometheus) | Metrics for monitoring |

## Troubleshooting

### Re-authenticate Downloader

```bash
docker run --rm -v hytale-downloader:/downloader alpine \
  rm -f /downloader/.hytale-downloader-credentials.json
docker compose run -it hytale
```

### Players Can't Connect

1. Verify **UDP** port forwarding (not TCP!)
2. Check firewall allows UDP traffic
3. Authenticate server: `/auth login device` in console

### Check Logs

```bash
docker compose logs -f
docker compose logs --tail 100
```

## License

This Docker configuration is provided as-is. Hytale and related assets are property of Hypixel Studios.
