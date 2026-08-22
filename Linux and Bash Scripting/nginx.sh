#!/bin/bash
sudo apt update 

sudo apt install nginx -y 

sudo systemctl start nginx 

sudo systemctl enable nginx 

sudo tee /var/www/html/index.html > /dev/null <<EOF 

<!DOCTYPE html> 

<html> 

<head> 

    <title>My Static Web Page</title> 

</head> 

<body style="text-align:center; font-family:Arial;"> 

    <h1>Welcome to My Web Server</h1> 

    <p>Sidheswar Mahapatra</p> 

</body> 

  

</html> 

EOF 

sudo systemctl restart nginx  

hostname -I 

echo "Static webpage deployed successfully!" 
