#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
sudo bash -c 'cat > /var/www/html/index.html' <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Q4 Terraform Nginx</title>
</head>
<body>
    <h1>Nginx Server Created Using Terraform</h1>
    <p>Nginx is running successfully.</p>
</body>
</html>
EOF
echo "NGINX SERVER CREATED SUCCESSFULLY"
