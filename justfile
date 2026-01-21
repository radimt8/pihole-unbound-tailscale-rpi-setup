# Pi-hole + Unbound + Tailscale management

# Show available commands
default:
    @just --list

# Initial setup - install Docker and deploy containers
setup:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "🔧 Installing Docker..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        echo "✅ Docker installed! Please log out and back in, then run 'just deploy'"
    else
        echo "✅ Docker already installed"
        just deploy
    fi

# Deploy containers
deploy:
    #!/usr/bin/env bash
    set -euo pipefail
    
    if [ ! -f .env ]; then
        echo "❌ .env file not found!"
        echo "Create .env with:"
        echo "  TZ=Europe/Prague"
        echo "  FTLCONF_webserver_api_password=your_password"
        exit 1
    fi
    
    echo "🚀 Deploying Pi-hole + Unbound..."
    docker compose up -d
    echo "✅ Deployed! Access Pi-hole at http://$(hostname -I | awk '{print $1}')/admin"

# Start containers
start:
    @echo "▶️  Starting containers..."
    @docker compose start
    @echo "✅ Started"

# Stop containers
stop:
    @echo "⏹️  Stopping containers..."
    @docker compose stop
    @echo "✅ Stopped"

# Restart Pi-hole (keeps Unbound running)
restart:
    @echo "🔄 Restarting Pi-hole..."
    @docker restart pihole
    @echo "✅ Restarted"

# Restart all containers
restart-all:
    @echo "🔄 Restarting all containers..."
    @docker compose restart
    @echo "✅ Restarted"

# View logs (follow mode)
logs:
    @docker compose logs -f

# View Pi-hole logs only
logs-pihole:
    @docker logs -f pihole

# View Unbound logs only
logs-unbound:
    @docker logs -f unbound

# Show container status
status:
    @echo "📊 Container Status:"
    @docker compose ps
    @echo ""
    @echo "🌐 Pi-hole Dashboard: http://$(hostname -I | awk '{print $1}')/admin"

# Update containers to latest versions
update:
    @echo "⬇️  Pulling latest images..."
    @docker compose pull
    @echo "🔄 Recreating containers..."
    @docker compose up -d
    @echo "✅ Updated"

# Update Pi-hole gravity (blocklists)
update-gravity:
    @echo "📡 Updating Pi-hole gravity..."
    @docker exec pihole pihole -g
    @echo "✅ Gravity updated"

# Show Pi-hole stats
stats:
    @docker exec pihole pihole -c -e

# Backup Pi-hole configuration
backup:
    #!/usr/bin/env bash
    set -euo pipefail
    
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    echo "💾 Backing up Pi-hole config..."
    docker cp pihole:/etc/pihole/ "$BACKUP_DIR/"
    docker cp pihole:/etc/dnsmasq.d/ "$BACKUP_DIR/"
    
    echo "✅ Backup saved to $BACKUP_DIR"

# Setup Tailscale with exit node
tailscale-setup:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "🔧 Setting up Tailscale..."
    
    # Install Tailscale if not present
    if ! command -v tailscale &> /dev/null; then
        echo "📥 Installing Tailscale..."
        curl -fsSL https://tailscale.com/install.sh | sh
    else
        echo "✅ Tailscale already installed"
    fi
    
    # Enable IP forwarding
    echo "🔧 Enabling IP forwarding..."
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv6.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
    else
        echo "✅ IP forwarding already enabled"
    fi
    
    # Setup UDP GRO if on WiFi
    if ip link show wlan0 &> /dev/null; then
        echo "🔧 Setting up UDP GRO for WiFi..."
        sudo ethtool -K wlan0 rx-udp-gro-forwarding on 2>/dev/null || true
    fi
    
    # Start Tailscale
    echo "🚀 Starting Tailscale with exit node..."
    sudo tailscale up --advertise-exit-node --accept-dns=false
    
    echo ""
    echo "✅ Tailscale setup complete!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Go to https://login.tailscale.com/admin/machines"
    echo "2. Find this device ($(hostname)) and approve as exit node"
    echo "3. Go to DNS tab and add this device's Tailscale IP as nameserver"
    echo "4. Enable 'Override local DNS'"
    echo ""
    echo "Your Tailscale IP: $(tailscale ip -4)"

# Show Tailscale status
tailscale-status:
    @sudo tailscale status

# Destroy everything (containers, volumes, configs)
destroy:
    #!/usr/bin/env bash
    read -p "⚠️  This will delete all Pi-hole data! Continue? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Destroying containers and volumes..."
        docker compose down -v
        echo "✅ Destroyed"
    else
        echo "❌ Cancelled"
    fi

# Clean up stopped containers and unused images
clean:
    @echo "🧹 Cleaning up..."
    @docker system prune -f
    @echo "✅ Cleaned"
