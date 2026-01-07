#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo)."
  exit 1
fi

echo "[1/8] Installing Tor on host..."
apt update
apt install -y tor

echo "[2/8] Enabling and starting tor.service..."
systemctl enable --now tor

echo "[3/8] Detecting docker0 IP and subnet..."
if ! ip link show docker0 >/dev/null 2>&1; then
  echo "ERROR: docker0 interface not found. Is Docker installed/running?"
  exit 1
fi

DOCKER0_IP="$(ip -4 addr show docker0 | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1)"
DOCKER0_CIDR="$(ip -4 route show dev docker0 | awk '{print $1}' | head -n1)"

if [[ -z "$DOCKER0_IP" || -z "$DOCKER0_CIDR" ]]; then
  echo "ERROR: Failed to detect docker0 IP/CIDR."
  exit 1
fi

echo "  docker0 ip:   $DOCKER0_IP"
echo "  docker0 cidr: $DOCKER0_CIDR"

echo "[4/8] Configuring Tor SOCKS on localhost + docker0..."
TORRC="/etc/tor/torrc"
cp "$TORRC" "${TORRC}.bak.$(date +%F-%H%M%S)"

# Remove any existing SOCKS directives to avoid conflicts
sed -i \
  -e '/^SocksPort /d' \
  -e '/^SOCKSPort /d' \
  -e '/^SocksListenAddress /d' \
  -e '/^SocksPolicy /d' \
  "$TORRC"

cat >> "$TORRC" <<EOF

## Added by tor_for_firefox_container_hostmode.sh
SocksPort 127.0.0.1:9050
SocksPort ${DOCKER0_IP}:9050

SocksPolicy accept 127.0.0.1/32
SocksPolicy accept ${DOCKER0_CIDR}
SocksPolicy reject *
EOF

systemctl restart tor

echo "[5/8] Verifying Tor is listening on both addresses..."
echo "  (expect: 127.0.0.1:9050 AND ${DOCKER0_IP}:9050)"
ss -lntp | grep 9050 || true

if ! ss -lntp | grep -q "127.0.0.1:9050"; then
  echo "ERROR: Tor not listening on 127.0.0.1:9050"
  echo "Check logs: sudo journalctl -u tor -n 200 --no-pager"
  exit 1
fi
if ! ss -lntp | grep -q "${DOCKER0_IP}:9050"; then
  echo "ERROR: Tor not listening on ${DOCKER0_IP}:9050"
  echo "Check logs: sudo journalctl -u tor -n 200 --no-pager"
  exit 1
fi

echo "[6/8] Adding UFW rule only if UFW is active..."
if command -v ufw >/dev/null 2>&1; then
  if ufw status | head -n1 | grep -qi "Status: active"; then
    ufw allow in on docker0 from "$DOCKER0_CIDR" to "$DOCKER0_IP" port 9050 proto tcp
    ufw reload
  else
    echo "  UFW installed but inactive; skipping."
  fi
else
  echo "  UFW not installed; skipping."
fi

echo "[7/8] (Re)creating the Firefox container..."


echo "  Removing existing container '$NAME'..."
docker rm -f firefox >/dev/null
docker run -d \
  --name=firefox \
  --security-opt seccomp=unconfined \
  --add-host=host.docker.internal:host-gateway \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -e LIBGL_ALWAYS_SOFTWARE=1 \
  -e FIREFOX_CLI=https://www.linuxserver.io/ \
  -p 127.0.0.1:3000:3000 \
  -p 127.0.0.1:3001:3001 \
  -v /path/to/config:/config \
  --shm-size="1gb" \
  --restart unless-stopped \
  lscr.io/linuxserver/firefox:latest


echo "[8/8] Verifying IPs..."
HOST_DIRECT="$(curl -s https://api.ipify.org || true)"
HOST_TOR="$(curl -s --socks5-hostname 127.0.0.1:9050 https://api.ipify.org || true)"
CONT_TOR="$(docker exec -i "$NAME" sh -lc 'curl -s --socks5-hostname host.docker.internal:9050 https://api.ipify.org' 2>/dev/null || true)"

echo "  Host direct IP:     ${HOST_DIRECT}"
echo "  Host via Tor IP:    ${HOST_TOR}"
echo "  Container via Tor:  ${CONT_TOR}"
echo
echo "Next manual step (inside container Firefox UI):"
echo "  Settings -> Network Settings -> Manual proxy"
echo "  SOCKS v5: host.docker.internal  Port: 9050"
echo "  Enable: 'Proxy DNS when using SOCKS v5'"
echo "In the Firefox address bar, type: about:config"
echo "  Search: network.proxy.socks_remote_dns and set to true"
echo "  Search: network.proxy.type and set to 1"
echo "Done."
