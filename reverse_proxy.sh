#!/bin/bash
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    REGION="eu-north-1"
fi
INSTANCE_TYPE="t3.micro"
echo "FINDING DEFAULT VPC"
VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=is-default,Values=true \
    --query 'Vpcs[0].VpcId' \
    --output text)
echo "VPC ID: $VPC_ID"
echo "FINDING SUBNET"
SUBNET_ID=$(aws ec2 describe-subnets \
    --filters Name=vpc-id,Values="$VPC_ID" \
    --query 'Subnets[0].SubnetId' \
    --output text)
echo "Subnet ID: $SUBNET_ID"
echo "FINDING LATEST UBUNTU AMI"
AMI_ID=$(aws ec2 describe-images \
    --owners 099720109477 \
    --filters \
        "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
        "Name=state,Values=available" \
        "Name=architecture,Values=x86_64" \
    --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
    --output text)
echo "AMI ID: $AMI_ID"
echo "CREATING BACKEND SECURITY GROUP"
BACKEND_SG=$(aws ec2 create-security-group \
    --group-name "q14-backend-sg" \
    --description "Security group for Q14 backend servers" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)
echo "Backend SG: $BACKEND_SG"
echo "CREATING PROXY SECURITY GROUP"
PROXY_SG=$(aws ec2 create-security-group \
    --group-name "q14-proxy-sg" \
    --description "Security group for Q14 reverse proxy" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)
echo "Proxy SG: $PROXY_SG"
echo "ALLOWING HTTP TO PROXY"
aws ec2 authorize-security-group-ingress \
    --group-id "$PROXY_SG" \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0
echo "ALLOWING HTTP FROM PROXY TO BACKENDS"
aws ec2 authorize-security-group-ingress \
    --group-id "$BACKEND_SG" \
    --protocol tcp \
    --port 80 \
    --source-group "$PROXY_SG"
echo "CREATING BACKEND USER DATA"
cat > backend-user-data.sh <<'EOF'
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
EOF
echo "LAUNCHING BACKEND SERVER 1"
BACKEND1_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID" \
    --security-group-ids "$BACKEND_SG" \
    --user-data file://backend-user-data.sh \
    --query 'Instances[0].InstanceId' \
    --output text)
aws ec2 create-tags \
    --resources "$BACKEND1_ID" \
    --tags Key=Name,Value=q14-backend1
echo "Backend 1: $BACKEND1_ID"
echo "LAUNCHING BACKEND SERVER 2"
BACKEND2_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID" \
    --security-group-ids "$BACKEND_SG" \
    --user-data file://backend-user-data.sh \
    --query 'Instances[0].InstanceId' \
    --output text)
aws ec2 create-tags \
    --resources "$BACKEND2_ID" \
    --tags Key=Name,Value=q14-backend2
echo "Backend 2: $BACKEND2_ID"
echo "WAITING FOR BACKEND SERVERS"
aws ec2 wait instance-running \
    --instance-ids "$BACKEND1_ID" "$BACKEND2_ID"
echo "GETTING BACKEND PRIVATE IPs"
BACKEND1_IP=$(aws ec2 describe-instances \
    --instance-ids "$BACKEND1_ID" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)
BACKEND2_IP=$(aws ec2 describe-instances \
    --instance-ids "$BACKEND2_ID" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)
echo "Backend 1 Private IP: $BACKEND1_IP"
echo "Backend 2 Private IP: $BACKEND2_IP"
echo "CREATING REVERSE PROXY USER DATA"
cat > proxy-user-data.sh <<EOF
#!/bin/bash
apt update -y
apt install nginx -y
cat > /etc/nginx/sites-available/default <<NGINX
upstream backend_servers {
    server $BACKEND1_IP:80;
    server $BACKEND2_IP:80;
}
server {
    listen 80;
    listen [::]:80;

    location / {
        proxy_pass http://backend_servers;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX
nginx -t
systemctl enable nginx
systemctl restart nginx
EOF
echo "LAUNCHING REVERSE PROXY"

PROXY_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID" \
    --security-group-ids "$PROXY_SG" \
    --user-data file://proxy-user-data.sh \
    --query 'Instances[0].InstanceId' \
    --output text)
aws ec2 create-tags \
    --resources "$PROXY_ID" \
    --tags Key=Name,Value=q14-reverse-proxy
echo "Reverse Proxy: $PROXY_ID"
echo "WAITING FOR REVERSE PROXY"
aws ec2 wait instance-running \
    --instance-ids "$PROXY_ID"\
echo "GETTING PROXY PUBLIC IP"
PROXY_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$PROXY_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)
echo "Backend 1 ID:       $BACKEND1_ID"
echo "Backend 1 IP:       $BACKEND1_IP"
echo "Backend 2 ID:       $BACKEND2_ID"
echo "Backend 2 IP:       $BACKEND2_IP"
echo "Reverse Proxy ID:   $PROXY_ID"
echo "Proxy Public IP:    $PROXY_PUBLIC_IP"
echo "http://$PROXY_PUBLIC_IP"
