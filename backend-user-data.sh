#!/bin/bash
apt update -y
apt install nginx -y
PRIVATE_IP=$(hostname -I | awk '{print $1}')
cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Q14 Backend Server</title>
</head>
<body>
    <h1>Backend Web Server</h1>
    <p>Private IP: $PRIVATE_IP</p>
</body>
</html>
HTML

systemctl enable nginx
systemctl restart nginx
