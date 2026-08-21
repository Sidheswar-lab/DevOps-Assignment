#!/bin/bash
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_CIDR="10.0.1.0/24"
PRIVATE_SUBNET_CIDR="10.0.2.0/24"
AZ=$(aws ec2 describe-availability-zones \
    --filters Name=state,Values=available \
    --query 'AvailabilityZones[0].ZoneName' \
    --output text)
echo "AVAILABILITY ZONE: $AZ"
echo "CREATING VPC"
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block "$VPC_CIDR" \
    --query 'Vpc.VpcId' \
    --output text)
echo "VPC ID: $VPC_ID"
aws ec2 create-tags \
    --resources "$VPC_ID" \
    --tags Key=Name,Value=Q12-VPC
echo "ENABLING DNS SUPPORT"
aws ec2 modify-vpc-attribute \
    --vpc-id "$VPC_ID" \
    --enable-dns-support '{"Value":true}'
aws ec2 modify-vpc-attribute \
    --vpc-id "$VPC_ID" \
    --enable-dns-hostnames '{"Value":true}'
echo "CREATING PUBLIC SUBNET"
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block "$PUBLIC_SUBNET_CIDR" \
    --availability-zone "$AZ" \
    --query 'Subnet.SubnetId' \
    --output text)
echo "Public Subnet ID: $PUBLIC_SUBNET_ID"
aws ec2 create-tags \
    --resources "$PUBLIC_SUBNET_ID" \
    --tags Key=Name,Value=Q12-Public-Subnet
echo "CREATING PRIVATE SUBNET"
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block "$PRIVATE_SUBNET_CIDR" \
    --availability-zone "$AZ" \
    --query 'Subnet.SubnetId' \
    --output text)
echo "Private Subnet ID: $PRIVATE_SUBNET_ID"
aws ec2 create-tags \
    --resources "$PRIVATE_SUBNET_ID" \
    --tags Key=Name,Value=Q12-Private-Subnet
echo "CREATING INTERNET GATEWAY"
IGW_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)
echo "Internet Gateway ID: $IGW_ID"
aws ec2 create-tags \
    --resources "$IGW_ID" \
    --tags Key=Name,Value=Q12-IGW
echo "ATTACHING INTERNET GATEWAY"
aws ec2 attach-internet-gateway \
    --internet-gateway-id "$IGW_ID" \
    --vpc-id "$VPC_ID"
echo "ALLOCATING ELASTIC IP FOR NAT GATEWAY"
ALLOCATION_ID=$(aws ec2 allocate-address \
    --domain vpc \
    --query 'AllocationId' \
    --output text)
echo "Allocation ID: $ALLOCATION_ID"
echo "CREATING NAT GATEWAY"
NAT_GW_ID=$(aws ec2 create-nat-gateway \
    --subnet-id "$PUBLIC_SUBNET_ID" \
    --allocation-id "$ALLOCATION_ID" \
    --query 'NatGateway.NatGatewayId' \
    --output text)
echo "NAT Gateway ID: $NAT_GW_ID"
echo "WAITING FOR NAT GATEWAY"
aws ec2 wait nat-gateway-available \
    --nat-gateway-ids "$NAT_GW_ID"
echo "CREATING PUBLIC ROUTE TABLE"
PUBLIC_RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --query 'RouteTable.RouteTableId' \
    --output text)
echo "Public Route Table ID: $PUBLIC_RT_ID"

aws ec2 create-tags \
    --resources "$PUBLIC_RT_ID" \
    --tags Key=Name,Value=Q12-Public-Route-Table
echo "ADDING PUBLIC ROUTE"
aws ec2 create-route \
    --route-table-id "$PUBLIC_RT_ID" \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id "$IGW_ID"
echo "ASSOCIATING PUBLIC SUBNET"
aws ec2 associate-route-table \
    --route-table-id "$PUBLIC_RT_ID" \
    --subnet-id "$PUBLIC_SUBNET_ID"
echo "CREATING PRIVATE ROUTE TABLE"
PRIVATE_RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --query 'RouteTable.RouteTableId' \
    --output text)
echo "Private Route Table ID: $PRIVATE_RT_ID"
aws ec2 create-tags \
    --resources "$PRIVATE_RT_ID" \
    --tags Key=Name,Value=Q12-Private-Route-Table
echo "ADDING PRIVATE ROUTE THROUGH NAT"
aws ec2 create-route \
    --route-table-id "$PRIVATE_RT_ID" \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id "$NAT_GW_ID"
echo "ASSOCIATING PRIVATE SUBNET"
aws ec2 associate-route-table \
    --route-table-id "$PRIVATE_RT_ID" \
    --subnet-id "$PRIVATE_SUBNET_ID"
echo "VPC ID:              $VPC_ID"
echo "Public Subnet ID:    $PUBLIC_SUBNET_ID"
echo "Private Subnet ID:   $PRIVATE_SUBNET_ID"
echo "Internet Gateway:    $IGW_ID"
echo "NAT Gateway:         $NAT_GW_ID"
echo "Public Route Table:  $PUBLIC_RT_ID"
echo "Private Route Table: $PRIVATE_RT_ID"
echo "=========================================="
