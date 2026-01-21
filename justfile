# Pi-hole + Unbound + Tailscale Setup

# Step 1: Install Docker (run this first)
install-docker:
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $(whoami)
    rm get-docker.sh
    @echo "✅ Docker installed! Exit and log back in, then run: just setup"

# Step 2: Complete setup (after relog)
setup: install-tailscale start
    @echo "✅ Setup complete!"
    @echo "Pi-hole admin: http://$(hostname -I | awk '{print $1}')/admin"
    @echo "Password: Check docker-compose.yml"

# Install Tailscale
install-tailscale:
    curl -fsSL https://tailscale.com/install.sh | sh
    @echo "Authenticating Tailscale (opens browser)..."
    sudo tailscale up --accept-dns=false

# Start everything
start:
    @echo "Starting Tailscale..."
    -sudo tailscale up --accept-dns=false
    @echo "Starting Pi-hole + Unbound..."
    docker compose up -d
    @echo "✅ All services running!"

# Stop everything
stop:
    docker compose down
    sudo tailscale down
    @echo "✅ All services stopped"

# Restart Pi-hole
restart:
    docker compose restart

# View logs
logs service="":
    @if [ -z "{{service}}" ]; then \
        docker compose logs -f; \
    else \
        docker compose logs -f {{service}}; \
    fi

# Update containers
update:
    docker compose pull
    docker compose up -d
    @echo "✅ Containers updated!"

# Show status
status:
    @echo "=== Tailscale Status ==="
    sudo tailscale status
    @echo ""
    @echo "=== Docker Status ==="
    docker ps
    @echo ""
    @echo "=== Pi-hole Stats ==="
    curl -s http://localhost/admin/api.php\?summaryRaw | jq '.'

# Backup configuration
backup:
    tar -czf pihole-backup-$(date +%Y%m%d-%H%M%S).tar.gz pihole/ unbound/
    @echo "✅ Backup created!"

# Clean up everything (dangerous!)
clean:
    docker compose down -v
    sudo rm -rf pihole/ unbound/
    @echo "⚠️  All data deleted!"
