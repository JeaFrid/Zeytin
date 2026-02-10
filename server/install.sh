#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

set -e
clear

echo -e "${CYAN}>>> Zeytin & Nginx Auto-Installer${NC}"

sudo apt-get update -y
sudo apt-get install -y git curl unzip wget openssl nginx python3-venv

if ! command -v dart &> /dev/null; then
    wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
    echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart.list
    sudo apt-get update -y && sudo apt-get install -y dart
fi

git clone https://github.com/JeaFrid/Zeytin.git || true
cd Zeytin
dart pub get

echo -e "\n${YELLOW}>>> Do you want to enable Live Streaming & Calls (Installs Docker + LiveKit)? (y/n)${NC}"
read -p "Choice: " INSTALL_LIVEKIT

if [[ "$INSTALL_LIVEKIT" == "y" ]]; then
    echo -e "${CYAN}Checking/Installing Docker...${NC}"
    
    if ! command -v docker &> /dev/null; then
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update -y
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo usermod -aG docker $USER
    fi

    LK_API_KEY="api$(openssl rand -hex 8)"
    LK_SECRET="sec$(openssl rand -hex 16)"
    PUBLIC_IP=$(curl -s ifconfig.me)
    echo -e "${CYAN}Deploying LiveKit Container...${NC}"
    if [ "$(sudo docker ps -aq -f name=zeytin-livekit)" ]; then
        echo -e "${YELLOW}Removing existing (old) Zeytin LiveKit container...${NC}"
        sudo docker rm -f zeytin-livekit
    fi
    sudo docker run -d --name zeytin-livekit \
        --restart unless-stopped \
        -p 12133:7880 \
        -p 12134:7881 \
        -p 12135:7882/udp \
        -e LIVEKIT_KEYS="${LK_API_KEY}: ${LK_SECRET}" \
        livekit/livekit-server --dev --bind 0.0.0.0

    echo -e "${GREEN}LiveKit deployed locally!${NC}"
    CONFIG_FILE="lib/config.dart"
    sed -i "s|static String liveKitUrl = \".*\";|static String liveKitUrl = \"ws://${PUBLIC_IP}:12133\";|" $CONFIG_FILE
    sed -i "s|static String liveKitApiKey = \".*\";|static String liveKitApiKey = \"${LK_API_KEY}\";|" $CONFIG_FILE
    sed -i "s|static String liveKitSecretKey = \".*\";|static String liveKitSecretKey = \"${LK_SECRET}\";|" $CONFIG_FILE
    echo -e "${GREEN}Zeytin configuration updated with LiveKit credentials!${NC}"
fi


echo -e "\n${YELLOW}>>> Do you want to install and configure Nginx with SSL (Certbot via venv)? (y/n)${NC}"
read -p "Choice: " INSTALL_NGINX

if [[ "$INSTALL_NGINX" == "y" ]]; then
    read -p "Enter your Domain (e.g. zeytin.jeafriday.com): " DOMAIN_NAME
    read -p "Enter your Email for SSL Alerts: " EMAIL_ADDR
    if [ ! -f "/opt/certbot/venv/bin/certbot" ]; then
        echo -e "${CYAN}Certbot not found. Installing via Python venv...${NC}"
        sudo python3 -m venv /opt/certbot/
        sudo /opt/certbot/venv/bin/pip install --upgrade pip
        sudo /opt/certbot/venv/bin/pip install certbot certbot-nginx
        sudo ln -sf /opt/certbot/venv/bin/certbot /usr/bin/certbot
    fi
    NGINX_CONF="/etc/nginx/sites-available/zeytin"
    sudo bash -c "cat > $NGINX_CONF <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
}
EOF"
    sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
    echo -e "${CYAN}Requesting SSL Certificate...${NC}"
    sudo /opt/certbot/venv/bin/certbot certonly --webroot -w /var/www/html -d $DOMAIN_NAME --non-interactive --agree-tos -m $EMAIL_ADDR
    echo -e "${CYAN}Writing your custom final Nginx configuration...${NC}"
    sudo bash -c "cat > $NGINX_CONF <<EOF
server {
    server_name $DOMAIN_NAME;
    client_max_body_size 100M;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        proxy_pass http://127.0.0.1:12852;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Connection \\\$http_connection;
        proxy_set_header Host \\\$host;
        proxy_cache_bypass \\\$http_upgrade;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;

        # TRANSFER STABİLİTESİ
        proxy_buffering off;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    if (\\\$host = $DOMAIN_NAME) {
        return 301 https://\\\$host\\\$request_uri;
    } # managed by Certbot

    listen 80;
    server_name $DOMAIN_NAME;
    return 404; # managed by Certbot
}
EOF"
    sudo nginx -t && sudo systemctl restart nginx
    echo -e "${GREEN}Nginx is now running with your exact custom configuration!${NC}"
fi
echo -e "${CYAN}>>> Setting project permissions...${NC}"
mkdir -p zeytin zeytin_err
sudo chown -R $USER:$USER $(pwd)
chmod -R 755 $(pwd)
if [ -d "zeytin" ]; then
    chmod -R 777 zeytin
fi
if [ -d "zeytin_err" ]; then
    chmod -R 777 zeytin_err
fi
echo -e "\n${GREEN}INSTALLATION COMPLETE! Run: dart runner.dart${NC}"