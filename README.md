# Pi-hole + Unbound + Tailscale on Raspberry Pi Zero 2 W

*Network-wide ad blocking with recursive DNS and remote access*

## Why This Exists

Modern web browsing has become hostile: ads that jump around causing misclicks, trackers following you everywhere, pages re-rendering as marketing scripts load. This setup restores the web to something closer to its original vision - content you requested, delivered cleanly, without surveillance or manipulation.

It's like finding a clear mountain stream after years of drinking from a polluted river.

## What This Does

- **Blocks ads and trackers** across all devices on your network automatically
- **Recursive DNS resolution** via Unbound - no third-party DNS provider sees your queries
- **Remote access** via Tailscale - ad blocking even on mobile data
- **Zero maintenance** once configured
- **Runs on a $15 computer** consuming ~2 watts

## Hardware

- Raspberry Pi Zero 2 W (~850 CZK / $35 USD)
- microSD card 32GB (~300 CZK / $12 USD)
- Case, power supply, adapters (included in starter kit)
- **Total: ~1,400 CZK / $58 USD**
- **Power cost: ~30 CZK / $1.25 per year**

## Architecture

```
Your Devices → Router (DHCP: use Pi as DNS) → Pi-hole (blocks ads) → Unbound (recursive DNS) → Root DNS servers
                                                ↓
                                           Tailscale (remote access)
```

## Installation

### 1. Flash Raspberry Pi OS Lite

Use Raspberry Pi Imager:
- OS: Raspberry Pi OS Lite (64-bit)
- Configure WiFi and SSH before flashing
- Enable SSH, set username/password

### 2. Initial Pi Setup

```bash
ssh user@your-pi-ip
sudo apt update && sudo apt upgrade -y
```

### 3. Install Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in
```

### 4. Clone This Repo

```bash
git clone https://github.com/yourusername/pihole-unbound-tailscale-rpi-setup.git
cd pihole-unbound-tailscale-rpi-setup
```

### 5. Configure Environment

Create a `.env` file:

```bash
nano .env
```

Add:
```env
TZ=Europe/Prague
FTLCONF_webserver_api_password=your_secure_password_here
```

### 6. Deploy

```bash
docker compose up -d
```

Pi-hole will be accessible at `http://your-pi-ip/admin`

### 7. Configure Router DHCP

In your router's DHCP settings (usually under Network → DHCP):
- **Primary DNS server:** Set to Pi's IP address (e.g., `10.0.1.37`)
- **Secondary DNS:** Leave blank or set to `1.1.1.1` as fallback
- Save settings

All devices will now use Pi-hole automatically when they reconnect to WiFi!

### 8. Add Better Blocklists

Access Pi-hole admin at `http://your-pi-ip/admin`:

1. Go to **Adlists** in the left menu
2. Add this URL:
   ```
   https://big.oisd.nl
   ```
3. Click **Add**
4. Go to **Tools → Update Gravity**
5. Wait for update to complete (~1-2 minutes)

Your blocklist will grow from ~68K to ~373K domains!

### 9. Install Tailscale (Optional - For Remote Access)

Tailscale enables:
- Ad blocking on mobile data
- Remote SSH access to your Pi
- Privacy on public WiFi (traffic routes through home)

#### On the Pi:

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale and advertise as exit node
sudo tailscale up --advertise-exit-node --accept-dns=false
```

This will output a URL - open it in your browser and authenticate.

#### Enable IP Forwarding:

```bash
# Edit sysctl config
sudo nano /etc/sysctl.conf

# Add these lines at the end:
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

# Apply changes
sudo sysctl -p
```

#### Fix UDP GRO (Optional - Improves Performance):

```bash
# Enable UDP GRO forwarding
sudo ethtool -K wlan0 rx-udp-gro-forwarding on

# Make it permanent
sudo nano /etc/systemd/system/udp-gro-fix.service
```

Paste:
```ini
[Unit]
Description=Enable UDP GRO forwarding for Tailscale
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool -K wlan0 rx-udp-gro-forwarding on
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl daemon-reload
sudo systemctl enable udp-gro-fix.service
sudo systemctl start udp-gro-fix.service
```

#### Configure Tailscale Admin Console:

1. Go to https://login.tailscale.com/admin/machines
2. Find your Pi (raspberrypi)
3. Click the **...** menu → **Edit route settings**
4. Enable **"Use as exit node"**
5. Click **Save**

#### Configure DNS:

1. Go to https://login.tailscale.com/admin/dns
2. Click **Add nameserver**
3. Enter: `100.x.x.x` (your Pi's Tailscale IP - shown in Machines list)
4. Enable **"Use with exit node"**
5. Enable **"Override local DNS"** toggle
6. (Optional) Add search domain: `pi.hole`
7. Click **Save**

#### On Your Devices:

**Phone (Android/iOS):**
1. Install Tailscale app from store
2. Sign in with same account
3. Connect to network
4. Tap **"EXIT NODE: None"**
5. Select **"raspberrypi"**

**Laptop/Desktop:**
1. Download Tailscale from https://tailscale.com/download
2. Install and sign in
3. Connect to network
4. Select Pi as exit node (if desired)

#### Test Remote Access:

While on mobile data (WiFi off) with Tailscale connected:

1. **Check your IP:**
   - Visit https://ifconfig.me
   - Should show your home IP!

2. **Access Pi-hole remotely:**
   - Open `http://100.x.x.x/admin` (your Pi's Tailscale IP)
   - Should load the dashboard!

3. **Test ad blocking:**
   - Visit any ad-heavy site
   - Ads blocked even on mobile data! 🎉

## Configuration Files

### docker-compose.yml

```yaml
networks:
  dns_net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.23.0.0/16

services:
  pihole:
    container_name: pihole
    hostname: pihole
    image: pihole/pihole:latest
    networks:
      dns_net:
        ipv4_address: 172.23.0.7
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"
      - "443:443/tcp"
      # Uncomment if using Pi-hole as DHCP server
      #- "67:67/udp"
    environment:
      TZ: ${TZ}
      FTLCONF_webserver_api_password: ${FTLCONF_webserver_api_password}
      FTLCONF_dns_upstreams: 'unbound'
      FTLCONF_dns_listeningMode: 'all'
    volumes:
      - pihole_data:/etc/pihole/
      - pihole_dnsmasq:/etc/dnsmasq.d/
    cap_add:
      # Uncomment if using DHCP
      #- NET_ADMIN
      - SYS_NICE
    restart: unless-stopped
    depends_on:
      - unbound

  unbound:
    container_name: unbound
    image: mvance/unbound-rpi:latest
    networks:
      dns_net:
        ipv4_address: 172.23.0.8
    volumes:
      - ./unbound:/opt/unbound/etc/unbound
    restart: unless-stopped

volumes:
  pihole_data:
  pihole_dnsmasq:
```

### unbound/unbound.conf

```conf
server:
    cache-min-ttl: 300
    directory: "/opt/unbound/etc/unbound"
    do-ip4: yes
    do-ip6: yes
    do-tcp: yes
    do-udp: yes
    edns-buffer-size: 1232
    interface: 0.0.0.0
    port: 53
    prefer-ip6: no
    rrset-roundrobin: yes
    username: "_unbound"
    log-local-actions: no
    log-queries: no
    log-replies: no
    log-servfail: no
    logfile: /dev/null
    verbosity: 0
    
    # Performance tuning
    infra-cache-slabs: 4
    incoming-num-tcp: 10
    key-cache-slabs: 4
    msg-cache-size: 142768128
    msg-cache-slabs: 4
    num-queries-per-thread: 4096
    num-threads: 2
    outgoing-range: 8192
    rrset-cache-size: 285536256
    rrset-cache-slabs: 4
    minimal-responses: yes
    prefetch: yes
    prefetch-key: yes
    serve-expired: yes
    so-reuseport: yes
    
    # Privacy and security
    aggressive-nsec: yes
    delay-close: 10000
    do-daemonize: no
    do-not-query-localhost: no
    neg-cache-size: 4M
    qname-minimisation: yes
    
    # Access control
    access-control: 127.0.0.1/32 allow
    access-control: 192.168.0.0/16 allow
    access-control: 172.16.0.0/12 allow
    access-control: 10.0.0.0/8 allow
    access-control: fc00::/7 allow
    access-control: ::1/128 allow
    
    # DNSSEC
    auto-trust-anchor-file: "var/root.key"
    chroot: "/opt/unbound/etc/unbound"
    deny-any: yes
    harden-algo-downgrade: yes
    harden-below-nxdomain: yes
    harden-dnssec-stripped: yes
    harden-glue: yes
    harden-large-queries: yes
    harden-referral-path: no
    harden-short-bufsize: yes
    hide-http-user-agent: no
    hide-identity: yes
    hide-version: yes
    http-user-agent: "DNS"
    identity: "DNS"
    
    # Private address ranges
    private-address: 10.0.0.0/8
    private-address: 172.16.0.0/12
    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: fd00::/8
    private-address: fe80::/10
    private-address: ::ffff:0:0/96
    
    # Additional security
    ratelimit: 1000
    tls-cert-bundle: /etc/ssl/certs/ca-certificates.crt
    unwanted-reply-threshold: 10000
    use-caps-for-id: yes
    val-clean-additional: yes
```

## What You Get

### At Home:
- Network-wide ad blocking on all devices
- Recursive DNS (no third-party tracking)
- Typical blocking rate: 25-35% of requests
- Faster page loads (ads don't load)
- Reduced bandwidth usage

### On The Go (via Tailscale):
- Ad blocking on mobile data
- Privacy on public WiFi (traffic routes through home)
- Remote SSH access to Pi from anywhere
- Remote Pi-hole management at `http://100.x.x.x/admin`
- Your location appears as home

## Expected Results

In typical usage:
- **20-35% of DNS queries blocked**
- **~20,000 ads/trackers blocked per day** (single user)
- **~7 million blocked per year**
- Pages load noticeably faster
- No popups, no layout shifts, no misclicks
- The web feels calm again

## Maintenance

**Monthly:**
- Check Pi-hole dashboard to ensure it's running
- Update blocklists: Tools → Update Gravity

**Every few months:**
```bash
ssh user@your-pi-ip
docker compose pull
docker compose up -d
```

**That's it.** This setup is designed to be fire-and-forget.

## Troubleshooting

### Pi-hole not blocking ads:

1. Check DNS settings on your device:
   ```bash
   nslookup google.com
   ```
   Should show your Pi's IP as server

2. Test if Pi-hole is working:
   ```bash
   dig @your-pi-ip doubleclick.net
   ```
   Should return `0.0.0.0`

3. Verify router DHCP points to Pi

### Can't access Pi-hole remotely via Tailscale:

1. Check exit node is approved in Tailscale admin
2. Verify DNS override is enabled
3. On phone, make sure exit node is selected
4. Test connection: `ping 100.x.x.x`

### Unbound not working:

```bash
docker logs unbound
```

Should show no errors. If empty, that's good (verbosity is off).

### Check Pi-hole upstream:

Go to Pi-hole admin → Settings → DNS

Should show: `172.23.0.8#53` (Unbound's IP in Docker network)

## Philosophy

This project exists because the modern web has become adversarial. Websites assume you're there to be monetized, tracked, and manipulated. Every page load is an exercise in dodging dark patterns, dismissing popups, and watching content jump around as ads load.

This setup restores browsing to something resembling the early web: you request content, you get content. Nothing more. The difference is immediate and profound - it's not just about blocking ads, it's about reclaiming your attention and your privacy.

The web can be a mountain stream again. Clean, fast, and yours.

## Credits

- [Pi-hole](https://pi-hole.net/) - Network-wide ad blocking
- [Unbound](https://nlnetlabs.nl/projects/unbound/) - Recursive DNS resolver
- [Tailscale](https://tailscale.com/) - Zero-config VPN
- [OISD](https://oisd.nl/) - Excellent blocklist

## License

MIT - Do whatever you want with this

---

**Cost:** ~$58 USD one-time + $1.25/year power  
**Time to setup:** ~30 minutes  
**Maintenance:** ~5 minutes per month  
**Value:** Priceless
