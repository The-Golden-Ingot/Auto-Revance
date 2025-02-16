#!/bin/bash

# Setup Cloudflare warp for bypass cloudflare anti ddos APKMirror:
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
sudo apt-get update && sudo apt-get install -y cloudflare-warp

# Start warp-svc without systemd in container
if [ ! -d "/run/systemd/system" ]; then
    sudo mkdir -p /var/run/warp
    sudo warp-svc &
    sleep 5  # Wait for service to start
fi

# Register and connect
warp-cli --accept-tos registration new || true  # Ignore if already registered
warp-cli --accept-tos mode warp
warp-cli --accept-tos connect
sleep 5  # Give more time for connection to establish

# Verify warp status
output=$(curl -s --max-time 10 https://www.cloudflare.com/cdn-cgi/trace | awk -F'=' '/ip|colo|warp/ {printf "%s: %s\n", $1, $2}')
echo "$output"
warp=$(echo "$output" | awk -F':' '/warp/ {print $2}')

if [ "$warp" = " on" ]; then
    echo -e "\e[32m[+] Successful install Cloudflare Warp\e[0m"
else
    echo -e "\e[31m[-] Can't install Cloudflare Warp\e[0m"
fi

# Test connection to Uptodown
if ! curl -s --max-time 10 https://www.uptodown.com >/dev/null; then
    echo -e "\e[31m[-] Failed to connect to Uptodown\e[0m"
    echo "Network debug info:"
    warp-cli status
    curl -v https://www.uptodown.com
    exit 1
fi
