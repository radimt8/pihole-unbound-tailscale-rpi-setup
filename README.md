# Pi-hole + Unbound + Tailscale on Raspberry Pi Zero 2 W

Network-wide ad blocking with recursive DNS and remote access.

## Why

Modern web browsing is hostile: ads jump around causing misclicks, trackers follow you everywhere, pages re-render as scripts load. This restores the web to what it should be - content you requested, delivered cleanly.

Like finding a clear mountain stream after drinking from a polluted river.

## What You Get

**At home:**
- Network-wide ad blocking (all devices, automatic)
- Recursive DNS via Unbound (no third-party tracking)
- 25-35% blocking rate typical
- Faster page loads, less bandwidth

**On the go (via Tailscale):**
- Ad blocking on mobile data
- Privacy on public WiFi
- Remote SSH to Pi
- Remote Pi-hole management

## Hardware

- Raspberry Pi Zero 2 W + accessories: ~$58 USD
- Power: ~$1.25/year
- Setup time: ~30 minutes
- Maintenance: ~5 minutes/month

## Quick Start

### 1. Flash Pi

Use Raspberry Pi Imager:
- OS: Raspberry Pi OS Lite (64-bit)
- Pre-configure WiFi and SSH

### 2. Setup

```bash
ssh user@your-pi-ip
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in

# Clone and deploy
git clone https://github.com/yourusername/pihole-unbound-tailscale-rpi-setup.git
cd pihole-unbound-tailscale-rpi-setup
cp .env.example .env
nano .env  # Set TZ and password

just setup
```

### 3. Configure Router

Set your router's DHCP DNS to Pi's IP (e.g., `10.0.1.37`). All devices now use Pi-hole automatically.

### 4. Add Blocklists

Access `http://your-pi-ip/admin`:
- Adlists → Add `https://big.oisd.nl`
- Tools → Update Gravity

### 5. Tailscale (Optional)

```bash
just tailscale-setup
```

Follow prompts, then in Tailscale admin:
1. Approve Pi as exit node
2. Add Pi's Tailscale IP as nameserver
3. Enable "Override local DNS"

On phone: Tailscale app → Select Pi as exit node

## Available Commands

```bash
just setup          # Initial deployment
just start          # Start containers
just stop           # Stop containers
just restart        # Restart containers
just logs           # View logs
just status         # Show status
just update         # Update containers
just tailscale-setup # Setup Tailscale
```

## Expected Results

- 20-35% of queries blocked
- ~20,000 ads/trackers blocked per day (single user)
- Pages feel calm - no jumps, no misclicks
- The web, as it should be

## Troubleshooting

**Ads not blocked?**
```bash
dig @your-pi-ip doubleclick.net  # Should return 0.0.0.0
```

**Tailscale not working?**
- Check exit node approved in admin
- Verify DNS override enabled
- Select Pi as exit node on device

**Check upstream:**
Pi-hole admin → Settings → DNS → Should show `172.23.0.8#53`

## Philosophy

The modern web is adversarial. This setup restores it to something resembling the early web: you request content, you get content. Nothing more.

The difference is immediate and profound.

---

**Credits:** [Pi-hole](https://pi-hole.net/) • [Unbound](https://nlnetlabs.nl/projects/unbound/) • [Tailscale](https://tailscale.com/) • [OISD](https://oisd.nl/)
