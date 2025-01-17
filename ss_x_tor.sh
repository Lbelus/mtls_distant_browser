#!/bin/bash

echo "Updating package list and installing required packages..."
sudo apt update && sudo apt install -y shadowsocks-libev tor ufw redsocks

echo "Setting up Shadowsocks server..."
read -p "Enter password for Shadowsocks server: " SS_PASSWORD
sudo ss-server -s 0.0.0.0 -p 8388 -k "$SS_PASSWORD" -m aes-256-gcm &

echo "Configuring Tor..."
TOR_CONF="/etc/tor/torrc"
if ! grep -q "SocksPort 9050" "$TOR_CONF"; then
    echo "SocksPort 9050" | sudo tee -a "$TOR_CONF"
fi
if ! grep -q "SocksListenAddress 127.0.0.1" "$TOR_CONF"; then
    echo "SocksListenAddress 127.0.0.1" | sudo tee -a "$TOR_CONF"
fi

echo "Restarting Tor service..."
sudo service tor restart

echo "Configuring redsocks to redirect Shadowsocks traffic to Tor..."
REDSOCKS_CONF="/etc/redsocks.conf"
sudo tee "$REDSOCKS_CONF" > /dev/null <<EOL
base {
    log_debug = off;
    log_info = on;
    log = "file:/var/log/redsocks.log";
    daemon = on;
}

redsocks {
    local_ip = 127.0.0.1;
    local_port = 12345; # Port to capture traffic from Shadowsocks
    ip = 127.0.0.1;
    port = 9050; # Tor SOCKS5 port
    type = socks5;
}
EOL

echo "Starting redsocks..."
sudo systemctl enable redsocks
sudo systemctl start redsocks

echo "Configuring firewall rules..."
sudo ufw default deny incoming

sudo ufw default allow outgoing
sudo ufw allow 8388/tcp  # Shadowsocks
sudo ufw allow 9050/tcp  # Tor SOCKS port
sudo ufw allow 12345/tcp # Redsocks local port

# Block non-Tor traffic
sudo ufw deny out from any to any
sudo ufw allow out to 127.0.0.1 port 9050 proto tcp # Allow Tor
sudo ufw allow out to 127.0.0.1 port 12345 proto tcp # Allow redsocks

sudo ufw enable
sudo ufw reload


echo "Setup complete!"
echo "Shadowsocks server is running on port 8388."
echo "Redsocks is redirecting traffic from Shadowsocks to Tor."
echo "Tor is running and listening on 127.0.0.1:9050."
