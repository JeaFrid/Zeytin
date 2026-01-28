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
sudo apt-get install -y git curl unzip wget openssl nginx

if ! command -v dart &> /dev/null; then
    wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
    echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart.list
    sudo apt-get update -y && sudo apt-get install -y dart
fi
git clone https://github.com/JeaFrid/zeytin.git || true
cd zeytin
dart pub get

echo -e "\n${YELLOW}>>> Do you want to install and configure Nginx? (y/n)${NC}"
read -p "Choice: " INSTALL_NGINX

if [[ "$INSTALL_NGINX" == "y" ]]; then
    read -p "Enter your Domain or IP (e.g. api.example.com): " DOMAIN_NAME
    
    NGINX_CONF="/etc/nginx/sites-available/zeytin"
    
    echo -e "${CYAN}Writing Nginx configuration...${NC}"
    sudo bash -c "cat > $NGINX_CONF <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://127.0.0.1:12852;
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
    sudo nginx -t && sudo systemctl restart nginx
    echo -e "${GREEN}Nginx configured for $DOMAIN_NAME${NC}"
fi

echo -e "\n${GREEN}INSTALLATION COMPLETE! Run: dart runner.dart${NC}"