#!/bin/bash
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    REGION="eu-north-1"
fi
INSTANCE_TYPE="t3.micro"
DASHBOARD_NAME="q16-ec2-dashboard"
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
echo "LAUNCHING EC2 INSTANCE"
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID" \
    --monitoring Enabled=true \
    --query 'Instances[0].InstanceId' \
    --output text)
echo "Instance ID: $INSTANCE_ID"
echo "WAITING FOR INSTANCE"
aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID"
echo "CREATING CLOUDWATCH DASHBOARD"
cat > dashboard.json <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "title": "CPU Utilization",
                "view": "timeSeries",
                "region": "$REGION",
                "metrics": [
                    [ "AWS/EC2", "CPUUtilization", "InstanceId", "$INSTANCE_ID" ]
                ],
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "title": "Network In",
                "view": "timeSeries",
                "region": "$REGION",
                "metrics": [
                    [ "AWS/EC2", "NetworkIn", "InstanceId", "$INSTANCE_ID" ]
                ],
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "title": "Network Out",
                "view": "timeSeries",
                "region": "$REGION",
                "metrics": [
                    [ "AWS/EC2", "NetworkOut", "InstanceId", "$INSTANCE_ID" ]
                ],
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "title": "Disk Read Operations",
                "view": "timeSeries",
                "region": "$REGION",
                "metrics": [
                    [ "AWS/EC2", "DiskReadOps", "InstanceId", "$INSTANCE_ID" ]
                ],
                "period": 300,
                "stat": "Average"
            }
        }
    ]
}
EOF
aws cloudwatch put-dashboard \
    --dashboard-name "$DASHBOARD_NAME" \
    --dashboard-body file://dashboard.json
echo "CREATING 4 CLOUDWATCH ALARMS"
aws cloudwatch put-metric-alarm \
    --alarm-name "q16-cpu-alarm" \
    --alarm-description "CPU utilization above 70 percent" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --evaluation-periods 1 \
    --threshold 70 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
    --treat-missing-data notBreaching
aws cloudwatch put-metric-alarm \
    --alarm-name "q16-network-in-alarm" \
    --alarm-description "Network In above threshold" \
    --metric-name NetworkIn \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --evaluation-periods 1 \
    --threshold 1000000 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
    --treat-missing-data notBreaching
aws cloudwatch put-metric-alarm \
    --alarm-name "q16-network-out-alarm" \
    --alarm-description "Network Out above threshold" \
    --metric-name NetworkOut \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --evaluation-periods 1 \
    --threshold 1000000 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
    --treat-missing-data notBreaching

aws cloudwatch put-metric-alarm \
    --alarm-name "q16-disk-read-alarm" \
    --alarm-description "Disk Read Operations above threshold" \
    --metric-name DiskReadOps \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --evaluation-periods 1 \
    --threshold 1000 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
    --treat-missing-data notBreaching
echo "VERIFYING DASHBOARD"
aws cloudwatch get-dashboard \
    --dashboard-name "$DASHBOARD_NAME" \
    --query 'DashboardName' \
    --output text
echo "VERIFYING ALARMS"

aws cloudwatch describe-alarms \
    --alarm-names \
        q16-cpu-alarm \
        q16-network-in-alarm \
        q16-network-out-alarm \
        q16-disk-read-alarm \
    --query 'MetricAlarms[*].[AlarmName,MetricName,Threshold,StateValue]' \
    --output table
echo "Instance ID: $INSTANCE_ID"
echo "Dashboard:   $DASHBOARD_NAME"
echo "Region:      $REGION"
