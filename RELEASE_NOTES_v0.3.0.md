## sigint-deck v0.3.0 - Antenna Arrays, SIEM, Sentinel Mode, Drone DF

### Multi-Device SDR & Antenna Arrays
- Detect ALL RTL-SDR devices (indices), ALL HackRF devices (serials)
- Auto-identify KrakenSDR (5ch) and KerberosSDR (4ch) coherent arrays
- Added Airspy, SDRplay, PlutoSDR detection
- Antenna position database with X/Y/Z coordinates, bearing, gain
- Quick setup presets: 4-Sector, 4-Sector Dual, KrakenSDR Center, Full 13-antenna
- Interactive canvas map with compass rose, range rings, color-coded bearing lines

### SIEM Event System
- SQLite FTS5 full-text search across all events
- 4GB rolling log budget with automatic pruning
- Time presets (Last Hour/24h/7d/30d), custom date range picker
- Watch mode with 5-second auto-refresh and rolling time window
- Export events to JSON

### Sentinel Mode
- Continuous autonomous threat monitoring toggle
- Starts all SDR monitors, 30-second watchlist scanning loop
- Threat watchlist database with MAC and RF signature matching

### Monitor Mode Diagnostics
- Step-by-step command output with pass/fail per step
- Replaced airmon-ng with nmcli device release (safe over SSH)
- sudo iw for phy detection and mode verification

### Comprehensive Setup Guide & BOM
- Full bill of materials with pricing ($1,800-$3,700 added cost)
- Baseline subtraction range estimates
- Legal notes (receive-only, FCC Part 15)

### Easter Egg
- Hidden SIGINT Training Ops game link in Settings

### Binary
- `sigint-deck-v0.3.0-x86_64-linux`: Steam Deck / x86_64 Linux (built with --features flipper)
