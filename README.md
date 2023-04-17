# s1-wiz
## Demo template/scripts
This repo contains some terraform templates to create:
- An Amazon Linux 2 EC2 instance in AWS that
    - Runs a vulnerable docker container (DVWA) - 447 issues
    - Is configured with an IAM Role with excessive (Admin) credentials

The template contains output variables that:
- Show the EC2 instance's public IP address (which can be used to launch a browser to access DVWA)
- An attack command to run within DVWA's Command Injection module (to be pasted into the input box) which:
    - Downloads the "s1-wiz-attack.sh" and executes it.  This script:
        - Scrapes credentials from the AWS IMDS service (metadata URL)
        - Creates a new credentials file in /home/$USER
        - Exports AWS-related environment variables
        - Installs AWSCLI if it isn't already installed
        - Uses AWSCLI to create a new EC2 instances to run a coinminer (XMRig)

