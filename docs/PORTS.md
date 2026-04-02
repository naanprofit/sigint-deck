# SIGINT-Deck Port Assignments

All network ports used by the SIGINT-Deck system and co-located services.

## SIGINT-Deck Ports

| Port | Protocol | Service | Bind Address | Notes |
|------|----------|---------|--------------|-------|
| **8085** | HTTP | SIGINT-Deck Web UI + API | `0.0.0.0` | Main web interface (Deck). Configurable in `config.toml` `[web] port` |
| **8080** | HTTP | SIGINT-Pi Web UI + API | `0.0.0.0` | Main web interface (Pi). Same software, different default port |
| **8082** | TCP | ADB forward (RayHunter) | `127.0.0.1` | ADB forwards phone:8080 -> localhost:8082. RayHunter HTTP API |
| **2947** | TCP | gpsd (GPS daemon) | `127.0.0.1` | GPS NMEA data from USB GPS receiver |
| **5037** | TCP | ADB daemon | `127.0.0.1` | Android Debug Bridge server |

## Co-located Services (Steam Deck)

| Port | Protocol | Service | Notes |
|------|----------|---------|-------|
| **11434** | HTTP | Ollama LLM | Local LLM inference. Used by SIGINT-Deck for AI analysis |
| **8081** | HTTP | Whisper Server | Python whisper_server.py for voice transcription. **Conflicts with old RayHunter port** |
| **22** | SSH | OpenSSH | Remote access |
| **27036** | TCP | Steam | Steam client remote play |
| **27060** | TCP | Steam | Steam client |
| **1716** | TCP | KDE Connect | Desktop connectivity |
| **53** | DNS | systemd-resolved | Local DNS resolver (127.0.0.53, 127.0.0.54) |
| **5355** | TCP | LLMNR | Link-Local Multicast Name Resolution |
| **631** | TCP | CUPS | Printing service |

## Co-located Services (Raspberry Pi)

| Port | Protocol | Service | Notes |
|------|----------|---------|-------|
| **8080** | HTTP | SIGINT-Pi Web UI | Main web interface |
| **2947** | TCP | gpsd | GPS daemon |
| **5037** | TCP | ADB daemon | For RayHunter phone (if connected to Pi) |
| **22** | SSH | OpenSSH | Remote access |

## RayHunter Phone (Orbic MDM9207)

| Port | Protocol | Service | Notes |
|------|----------|---------|-------|
| **8080** | HTTP | RayHunter API | Runs on phone, accessed via ADB forward to host:8082 |

## Known Conflicts

| Ports | Conflict | Resolution |
|-------|----------|------------|
| **8081** | Whisper server vs RayHunter ADB forward | Moved RayHunter to **8082**. Whisper stays on 8081 |
| **8080** | SIGINT-Pi web UI vs RayHunter phone API | No conflict: Pi web binds 0.0.0.0:8080, RayHunter is on phone (forwarded to 8082) |

## Configuration

### Changing SIGINT-Deck web port
```toml
# config.toml
[web]
bind_address = "0.0.0.0"
port = 8085
```

### Changing RayHunter forward port
```toml
# config.toml
[rayhunter]
api_url = "http://localhost:8082"
```
Also update `rayhunter-adb.sh`:
```bash
adb forward tcp:8082 tcp:8080
```

### Changing Ollama endpoint
```toml
# config.toml
[llm]
endpoint = "http://localhost:11434"
```

## Optional Services (not running by default)

| Port | Protocol | Service | Config Key |
|------|----------|---------|------------|
| **1883** | MQTT | Alert broker | `[alerts] mqtt_broker_port` |
| **587** | SMTP | Email alerts | `[alerts] smtp_port` |
| **4403** | TCP | Meshtastic | `[meshtastic] tcp_port` |
| **8082** | TCP | OpenClaw relay | `[openclaw] relay_listen_port` |

> **Note:** OpenClaw relay_listen_port defaults to 8082 which now conflicts with
> RayHunter ADB forward. If using OpenClaw mesh relay, change one of them.
