# Pi-hole + Unbound + Tailscale Setup

Complete network-wide ad-blocking with recursive DNS and secure remote access.

## Features

- 🏴‍☠️ **Pi-hole**: Network-wide ad blocking
- 🔐 **Unbound**: Recursive DNS with DNSSEC validation
- 🌐 **Tailscale**: Secure remote access from anywhere
- 🐳 **Docker**: Clean, isolated deployment
- ⚡ **Just**: Simple command runner

## Quick Start
```bash
# 1. Clone repo
git clone https://github.com/yourusername/pihole-tailscale-setup.git
cd pihole-tailscale-setup

# 2. Install Docker
just install-docker
# Exit and log back in

# 3. Complete setup
just setup
```

## Commands
```bash
just start      # Start all services
just stop       # Stop all services
just restart    # Restart Pi-hole
just logs       # View logs
just status     # Show status
just update     # Update containers
just backup     # Backup configs
```

## Configuration

1. Edit `docker-compose.yml` and change `WEBPASSWORD`
2. Access Pi-hole admin: `http://YOUR_PI_IP/admin`
3. Configure router DNS to point to Pi's IP

## Tailscale

After setup, your Pi is accessible via Tailscale from anywhere:
- SSH: `ssh user@100.x.x.x`
- Pi-hole: `http://100.x.x.x/admin`
- Set Pi as DNS in Tailscale for mobile ad-blocking

## Router Configuration

Set your router's DHCP DNS server to your Pi's IP address (e.g., `10.0.1.37`).

All devices on your network will automatically use Pi-hole for DNS.
