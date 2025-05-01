## EC2-creation and it's componet creations: 

aws ec2 run-instances \
  --image-id ami-0696195f0b2c390e8 \
  --count 2 \
  --instance-type m7g.xlarge \
  --key-name 	Raviraj \
  --security-group-ids sg-079e4dc5d60c396e2 \
  --subnet-id subnet-04fcfeaf2fe9a9565 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=RaviEC2Instance}]'



  Pre-requisits to create : !> subnet , VPC, security-group

###Subnet creations: 
aws ec2 create-subnet \
    --vpc-id vpc-0ab98e0b4f9030f36 \
    --cidr-block 192.168.0.0/16 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=RaviRaj},{Key=Purpose,Value=Testing}]'


  
###VPC creation : 
aws ec2 create-vpc \
    --cidr-block 192.168.1.140/16 \
    --region us-east-1

###AMI finding : 
aws ec2 describe-images     --owners amazon     --filters "Name=name,Values=*amazon-eks-arm64-node-1.21*" "Name=architecture,Values=arm64"     --query 'sort_by(Images, &CreationDate)[-1].ImageId'


##Key-pair: creation: 
aws ec2 create-key-pair   --key-name raviraj


Creating- security group :

aws ec2 create-security-group \
            --group-name MySecurityGroup \
            --description "RaviRajSG" \
            --vpc-id vpc-0ab98e0b4f9030f36


        aws ec2 create-security-group \
            --group-name MySecurityGroup \
            --description "My security group"

    aws ec2 authorize-security-group-ingress \
        --group-name MySecurityGroup \
        --group-id sg-903004f8 \  # Replace with the actual group ID
        --ip-protocol tcp \
        --port-range FromPort=22,ToPort=22 \
        --cidr MyIPAddress/32 # Replace with your IP address
