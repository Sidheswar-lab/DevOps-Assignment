#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
PRIVATE_IP=$(hostname -I | awk '{print $1}')
sudo bash -c "cat > /var/www/html/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Backend Server</title>
</head>
<body>
    <h1>Backend Server</h1>
    <p>Backend Private IP: $PRIVATE_IP</p>
</body>
</html>
EOF
echo "Backend Nginx server configured successfully"
