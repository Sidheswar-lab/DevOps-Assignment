#!/bin/bash

INSTANCE_TYPE="t3.micro"

echo "FINDING DEFAULT VPC"

VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=is-default,Values=true \
    --query 'Vpcs[0].VpcId' \
    --output text)

echo "VPC ID: $VPC_ID"

echo "FINDING DEFAULT SUBNET"

SUBNET_ID=$(aws ec2 describe-subnets \
    --filters Name=vpc-id,Values="$VPC_ID" \
    --query 'Subnets[0].SubnetId' \
    --output text)

echo "Subnet ID: $SUBNET_ID"

echo "FINDING LATEST UBUNTU LTS AMI"

AMI_ID=$(aws ec2 describe-images \
    --owners 099720109477 \
    --filters \
        "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
        "Name=state,Values=available" \
        "Name=architecture,Values=x86_64" \
        "Name=root-device-type,Values=ebs" \
    --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
    --output text)

echo "Latest Ubuntu AMI ID: $AMI_ID"

echo "LAUNCHING EC2 INSTANCE"

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instance ID: $INSTANCE_ID"

echo "WAITING FOR INSTANCE"

aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID"

echo "INSTANCE DETAILS"

aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[*].Instances[*].[InstanceId,ImageId,InstanceType,PrivateIpAddress,PublicIpAddress,State.Name]' \
    --output table

echo "Q8 COMPLETED SUCCESSFULLY"
