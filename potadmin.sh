#!/bin/bash

IAM_USER="pot-admin"
INSTANCE_TYPE="t3.micro"

echo "CREATING IAM USER"

aws iam create-user \
    --user-name "$IAM_USER"

echo "ATTACHING ADMINISTRATOR ACCESS"

aws iam attach-user-policy \
    --user-name "$IAM_USER" \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

echo "ATTACHING EC2 FULL ACCESS"

aws iam attach-user-policy \
    --user-name "$IAM_USER" \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

echo "IAM USER CREATED SUCCESSFULLY"

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

echo "Latest Ubuntu AMI: $AMI_ID"

echo "FINDING DEFAULT SUBNET"

VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=is-default,Values=true \
    --query 'Vpcs[0].VpcId' \
    --output text)

SUBNET_ID=$(aws ec2 describe-subnets \
    --filters Name=vpc-id,Values="$VPC_ID" \
    --query 'Subnets[0].SubnetId' \
    --output text)

echo "VPC ID: $VPC_ID"
echo "Subnet ID: $SUBNET_ID"

echo "LAUNCHING 3 EC2 INSTANCES"

for NAME in pot1 pot2 pot3
do
    echo "Launching $NAME"

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --subnet-id "$SUBNET_ID" \
        --query 'Instances[0].InstanceId' \
        --output text)

    echo "$NAME Instance ID: $INSTANCE_ID"

    aws ec2 create-tags \
        --resources "$INSTANCE_ID" \
        --tags Key=Name,Value="$NAME"

    echo "$NAME tagged successfully"
done

echo "WAITING FOR INSTANCES"

aws ec2 wait instance-running \
    --filters Name=tag:Name,Values=pot1,pot2,pot3

echo "INSTANCE DETAILS"

aws ec2 describe-instances \
    --filters Name=tag:Name,Values=pot1,pot2,pot3 \
    --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],PublicIpAddress,State.Name]' \
    --output table

echo "Q9 COMPLETED SUCCESSFULLY"
