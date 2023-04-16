#!/bin/bash

# Ensure that python3, python3-pip are installed
# Ensure that selenium module is installed:  pip3 install selenium
# ='\U'
# printf ${}

Color_Off='\033[0m'       # Text Reset
# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
# Emojis
UNICORN='\U1F984'
RAINBOW='\U1F308'
ROCKET='\U1F680'
HOURGLASS='\U23F3'
SMILE='\U1F600'
POOP='\U1F4A9'
COFFEE='\U2615'
BEER='\U1F37A'

# printf ${POOP}
# printf ${UNICORN}
# printf ${ROCKET}
# printf ${SMILE}
# printf ${RAINBOW}
# printf ${HOURGLASS}


################################################################################
# AWS
################################################################################
CSP='AWS'
printf "\n${Purple}Running Automation for $CSP...${Color_Off}\n"

printf "\n${Purple}Running 'terraform init'...${Color_Off}\n"
terraform init

printf "\n${Purple}Running 'terraform apply -auto-approve'...${Color_Off}\n"
terraform apply -auto-approve

# Insert wait loops to ensure that services are ready
# S1 deployed and registered to console
# DVWA services up and available

# insert sleep of 30 seconds (to give the s1-agent extra time to bootstrap itself fully)
printf "\n${Purple}Sleeping 30 seconds...${Color_Off}\n"
sleep 30


printf "\n${Purple}Waiting for DVWA to become ready...${Color_Off}\n"
DVWA_LB=$(terraform output -raw dvwa_loadbalancer_hostname)
until $(curl --output /dev/null --silent --head --fail http://$DVWA_LB:80); do
    printf '.'
    sleep 3
done

printf "\n${Purple}Attacking DVWA deployment on EKS...${Color_Off}\n"
python3 ../injection_headless.py $(terraform output -raw dvwa_loadbalancer_hostname) 80


printf "\n${Purple}Waiting for DVWA to become ready on EC2...${Color_Off}\n"
DVWA=$(terraform output -raw instance_EIP)
until $(curl --output /dev/null --silent --head --fail http://$DVWA:80); do
    printf '.'
    sleep 3
done

printf "\n${Purple}Attacking DVWA container on EC2...${Color_Off}\n"
python3 ../injection_headless.py $(terraform output -raw instance_EIP) 80

# printf "\n${Purple}Sleeping 10 seconds...${Color_Off}\n"
# sleep 10

# printf "\n${Purple}Running 'terraform destroy -auto-approve...${Color_Off}\n"
# terraform destroy -auto-approve

if [ $? == 0 ];then
    printf "\n${Green}AWS Done! ${Color_Off}  ${UNICORN} ${RAINBOW} ${SMILE}\n"
else
    printf "\n${Red}AWS Failed ${POOP}\n"
fi

cd ..



# TODO:
# Test each step for success/failure
# Email success/fail status of each scenario.
