#!/bin/bash

SG_NAME="q6-security-group"
INSTANCE_TYPE="t3.micro"
KEY_NAME="MyKey2"
echo "CREATING SECURITY GROUP"
VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=is-default,Values=true \
    --query 'Vpcs[0].VpcId' \
    --output text)
SG_ID=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description "Security group for Q6" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)
echo "Security Group ID: $SG_ID"
echo "CONFIGURING INBOUND SSH"
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0
echo "CONFIGURING OUTBOUND TRAFFIC"
aws ec2 authorize-security-group-egress \
    --group-id "$SG_ID" \
    --protocol -1 \
    --cidr 0.0.0.0/0 2>/dev/null
echo "FINDING UBUNTU AMI"
AMI_ID=$(aws ec2 describe-images \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
              "Name=state,Values=available" \
    --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
    --output text)
echo "AMI ID: $AMI_ID"
echo "LAUNCHING EC2 INSTANCE"
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --query 'Instances[0].InstanceId' \
    --output text)
echo "Instance ID: $INSTANCE_ID"
echo "WAITING FOR INSTANCE"
aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID"
echo "INSTANCE DETAILS"
aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[*].Instances[*].[InstanceId,PublicDnsName]' \
    --output table
