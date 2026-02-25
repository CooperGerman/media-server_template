#!/bin/bash

# 1. Copy config folders
# We check if folders exist, if not create them
SERVICES=("wireguard" "transmission" "rdtclient" "jellyfin" "sonarr" "radarr" "bazarr" "lidarr" "prowlarr" "seerr" "audiobookshelf" "flaresolverr")

mkdir -p configs
mkdir -p data

for SERVICE in "${SERVICES[@]}"; do
    mkdir -p "configs/$SERVICE"
    touch "configs/$SERVICE/.gitkeep"
done

# 2. Setup WireGuard Template
mkdir -p configs/wireguard/wg_confs
if [ ! -f "configs/wireguard/wg_confs/wg0.conf.example" ]; then
    echo "Creating wireguard template..."
    cat > configs/wireguard/wg_confs/wg0.conf.example <<EOL
[Interface]
# PRIVATE KEY IS REQUIRED HERE
PrivateKey = <YOUR_PRIVATE_KEY>
Address = 10.2.0.2/32
DNS = 1.1.1.1
# PostUp Rules are critical for local processing when accessing via LAN
PostUp = DROUTE=\$(ip route | grep default | awk '{print \$3}'); HOMENET=192.168.0.0/16; HOMENET2=10.0.0.0/8; HOMENET3=172.16.0.0/12; ip route add \$HOMENET3 via \$DROUTE;ip route add \$HOMENET2 via \$DROUTE; ip route add \$HOMENET via \$DROUTE;iptables -I OUTPUT -d \$HOMENET -j ACCEPT;iptables -A OUTPUT -d \$HOMENET2 -j ACCEPT; iptables -A OUTPUT -d \$HOMENET3 -j ACCEPT;  iptables -A OUTPUT ! -o %i -m mark ! --mark \$(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
PreDown = DROUTE=\$(ip route | grep default | awk '{print \$3}'); HOMENET=192.168.0.0/16; HOMENET2=10.0.0.0/8; HOMENET3=172.16.0.0/12; ip route del \$HOMENET3 via \$DROUTE;ip route del \$HOMENET2 via \$DROUTE; ip route del \$HOMENET via \$DROUTE; iptables -D OUTPUT ! -o %i -m mark ! --mark \$(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT; iptables -D OUTPUT -d \$HOMENET -j ACCEPT; iptables -D OUTPUT -d \$HOMENET2 -j ACCEPT; iptables -D OUTPUT -d \$HOMENET3 -j ACCEPT

[Peer]
# PEER KEY AND ENDPOINT
PublicKey = <PEER_PUBLIC_KEY>
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = <VPN_ENDPOINT_IP>:<PORT>
PersistentKeepalive = 25
EOL
fi

# 3. Setup Env
if [ ! -f ".env" ]; then
    echo "Creating .env from example..."
    cp .env.example .env
    echo "Please edit .env with your specific user IDs and settings."
fi

echo "Setup complete. "
echo "1. Edit .env"
echo "2. Add your wireguard config to configs/wireguard/wg_confs/wg0.conf (use wg0.conf.example as reference)"
echo "3. Run 'docker compose up -d'"
