
resource "random_pet" "name" {
}

# For full list of filters, see: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html

# Ubuntu Focal
#  name_regex       = "^ubuntu/images/hvm-ssd/ubuntu-focal-20.04.*"
#  owners           = ["099720109477"]

# Ubuntu Jammy
# name_regex       =  "^ubuntu/images/hvm-ssd/ubuntu-jammy-22.04.*"
# owners           = ["099720109477"]

# AL2
# name_regex       =  "^amzn2-ami-hvm-.*-gp2"
# owners           = ["137112412989"]

data "aws_ami" "latest_ami" {
  #executable_users = ["self"]
  most_recent = true
  # AL2
  name_regex = "^amzn2-ami-hvm-.*-gp2"
  owners     = ["137112412989"]

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "testInstance" {
  tags = merge(
    var.tags,
    {
      "Name" = "aws-amzn2"
    }
  )
  ami                    = data.aws_ami.latest_ami.image_id
  instance_type          = var.ec2_instance_type
  vpc_security_group_ids = [aws_security_group.sg_22.id]
  key_name               = var.keypair
  iam_instance_profile   = aws_iam_instance_profile.web_profile.name
  user_data              = <<EOF
#! /bin/bash
  hostnamectl set-hostname aws-amzn2
  curl -sLO 'https://raw.githubusercontent.com/s1-howie/s1-agents-helper/master/s1-agent-helper.sh'
  chmod +x s1-agent-helper.sh; ./s1-agent-helper.sh ${var.s1_console_prefix} ${var.s1_api_key} ${var.s1_site_token_aws} ${var.s1_agent_status}
  curl -sLO 'https://s1demostorageaccount.z13.web.core.windows.net/scripts/install_docker.sh'; chmod +x install_docker.sh; ./install_docker.sh
  docker run -d --name dvwa --restart unless-stopped -p 80:80 howiehowerton/dvwa-howie:v2
EOF 
}


resource "aws_security_group" "sg_22" {
  name = "aws-amzn2-cws-sg1"

  # SSH access from the VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.workstation-external-cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.workstation-external-cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}


resource "aws_iam_instance_profile" "web_profile" {
  name = "aws-amzn2-cws-instance-profile"
  role = aws_iam_role.web_role.name
}

resource "aws_iam_role" "web_role" {
  name = "aws-amzn2-cws-iam-role"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name = "aws-amzn2-inline-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["ec2:Describe*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}


output "instance_EIP" {
  value = aws_instance.testInstance.public_ip
}
output "connect_via_ssh" {
  value = "ssh -i ~/.ssh/${var.keypair}.pem ubuntu@${aws_instance.testInstance.public_ip}"
}
output "start_instance" {
  value = "aws ec2 start-instances --instance-ids ${aws_instance.testInstance.id}"
}
output "stop_instance" {
  value = "aws ec2 stop-instances --instance-ids ${aws_instance.testInstance.id}"
}
output "get_public_ip" {
  value = "aws ec2 describe-instances --instance-ids ${aws_instance.testInstance.id} | jq -r '.Reservations[].Instances[].PublicIpAddress'"
}
