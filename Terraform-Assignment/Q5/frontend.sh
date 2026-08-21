#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
sudo bash -c "cat > /var/www/html/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Frontend Server</title>
</head>
<body>
    <h1>Frontend Server</h1>
    <p>Backend Public IP: ${backend_public_ip}</p>
</body>
</html>
EOF
echo "Frontend server configured successfully"
