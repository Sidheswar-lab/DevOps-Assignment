#!/bin/bash
apt update -y
apt install nginx -y
cat > /etc/nginx/sites-available/default <<NGINX
upstream backend_servers {
    server 172.31.4.127:80;
    server 172.31.8.239:80;
}
server {
    listen 80;
    listen [::]:80;

    location / {
        proxy_pass http://backend_servers;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX
nginx -t
systemctl enable nginx
systemctl restart nginx
