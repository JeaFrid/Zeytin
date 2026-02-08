#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

set -e
clear

get_free_port() {
    local port=$1
    while (netstat -atn | grep -q ":$port ") || (command -v docker &> /dev/null && docker ps --format '{{.Ports}}' | grep -q ":$port->"); do
        port=$((port + 1))
    done
    echo $port
}

echo -e "${CYAN}>>> Zeytin & Nginx Auto-Installer${NC}"

sudo apt-get update -y
sudo apt-get install -y git curl unzip wget openssl nginx python3-venv net-tools

if ! command -v dart &> /dev/null; then
    wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
    echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart.list
    sudo apt-get update -y && sudo apt-get install -y dart
fi

git clone https://github.com/JeaFrid/Zeytin.git || true
cd Zeytin
dart pub get

ZEYTIN_PORT=$(get_free_port 12852)
echo -e "${GREEN}Selected Port for Zeytin: $ZEYTIN_PORT${NC}"

echo -e "\n${YELLOW}>>> Do you want to enable Live Streaming & Calls? (y/n)${NC}"
read -p "Choice: " INSTALL_LIVEKIT

if [[ "$INSTALL_LIVEKIT" == "y" ]]; then
    if ! command -v docker &> /dev/null; then
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update -y
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo usermod -aG docker $USER
    fi

    LK_HTTP_PORT=$(get_free_port 7880)
    LK_TCP_PORT=$(get_free_port 7881)
    LK_UDP_PORT=$(get_free_port 7882)
    LK_API_KEY="api$(openssl rand -hex 8)"
    LK_SECRET="sec$(openssl rand -hex 16)"
    LK_NAME="zeytin-livekit-$(openssl rand -hex 3)"
    PUBLIC_IP=$(curl -s ifconfig.me)

    sudo docker run -d --name "$LK_NAME" \
        --restart unless-stopped \
        -p "$LK_HTTP_PORT":7880 \
        -p "$LK_TCP_PORT":7881 \
        -p "$LK_UDP_PORT":7882/udp \
        -e LIVEKIT_KEYS="${LK_API_KEY}: ${LK_SECRET}" \
        livekit/livekit-server --dev --bind 0.0.0.0

    sed -i "s|static int serverPort = .*|static int serverPort = $ZEYTIN_PORT;|" lib/config.dart
    sed -i "s|static String liveKitUrl = .*|static String liveKitUrl = \"ws://${PUBLIC_IP}:${LK_HTTP_PORT}\";|" lib/config.dart
    sed -i "s|static String liveKitApiKey = .*|static String liveKitApiKey = \"${LK_API_KEY}\";|" lib/config.dart
    sed -i "s|static String liveKitSecretKey = .*|static String liveKitSecretKey = \"${LK_SECRET}\";|" lib/config.dart
fi

echo -e "\n${YELLOW}>>> Do you want to install and configure Nginx with SSL? (y/n)${NC}"
read -p "Choice: " INSTALL_NGINX

if [[ "$INSTALL_NGINX" == "y" ]]; then
    read -p "Enter your Domain: " DOMAIN_NAME
    read -p "Enter your Email: " EMAIL_ADDR
    NGINX_CONF="/etc/nginx/sites-available/zeytin-$ZEYTIN_PORT"
    
    sudo bash -c "cat > $NGINX_CONF <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        proxy_pass http://127.0.0.1:$ZEYTIN_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \\\$host;
        proxy_cache_bypass \\\$http_upgrade;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
    }
}
EOF"
    sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
    sudo nginx -t
    sudo systemctl restart nginx
    sudo python3 -m venv /opt/certbot/venv
    sudo /opt/certbot/venv/bin/pip install --upgrade pip
    sudo /opt/certbot/venv/bin/pip install certbot certbot-nginx
    sudo /opt/certbot/venv/bin/certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos -m $EMAIL_ADDR --redirect
fi

echo -e "\n${GREEN}INSTALLATION COMPLETE! Run: dart server/runner.dart${NC}"