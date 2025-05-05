##Take values from : " aws ec2 describe-vpcs  --output table"

#!/bin/bash
aws ec2 create-subnet \
    --vpc-id vpc-05396b6b029e5d2cf \
    --cidr-block 192.168.0.0/23 \
    --region us-east-1 \
    --availability-zone us-east-1a \
    --query 'Subnet.SubnetId' \
    --output text \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=RaviSubnet}]'
