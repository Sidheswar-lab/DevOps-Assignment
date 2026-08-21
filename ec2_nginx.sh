#!/bin/bash
echo "UPDATING SYSTEM"
sudo apt update -y
echo "INSTALLING NGINX"\
sudo apt install nginx -y
echo "GETTING PRIVATE IP"
PRIVATE_IP=$(hostname -I | awk '{print $1}')
echo "Private IP: $PRIVATE_IP"
echo "CONFIGURING INDEX.HTML"
sudo bash -c "cat > /var/www/html/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Nginx Server</title>
</head>
<body>
    <h1>Nginx Web Server</h1>
    <h2>Private IP Address: $PRIVATE_IP</h2>
</body>
</html>
EOF
echo "STARTING NGINX"
sudo systemctl enable nginx
sudo systemctl restart nginx
echo "CHECKING NGINX STATUS"
sudo systemctl status nginx --no-pager
echo "NGINX WEB SERVER CONFIGURED SUCCESSFULLY"
echo "Private IP: $PRIVATE_IP"
