# For full list of filters, see: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html

data "aws_ami" "latest_windows_2019_ami" {
  #executable_users = ["self"]
  most_recent = true
  # Windows Server 2019
  name_regex = "Windows_Server-2019-English-Full-Base-*"
  owners     = ["amazon"]

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

resource "aws_instance" "windowsInstance" {
  tags = merge(
    var.tags,
    {
      "Name" = "aws-Server2019"
    }
  )
  ami                    = data.aws_ami.latest_windows_2019_ami.image_id
  instance_type          = var.ec2_instance_type
  vpc_security_group_ids = [aws_security_group.sg_3389_80.id]
  key_name               = var.keypair
  iam_instance_profile   = aws_iam_instance_profile.windows_2019_profile.name
  user_data              = <<EOF
<powershell>
Set-ExecutionPolicy Unrestricted
(new-object Net.WebClient).DownloadFile("https://raw.githubusercontent.com/s1-howie/s1-agents-helper/main/s1-agent-helper.ps1", "$env:TEMP\s1-agent-helper.ps1") 
& "$env:TEMP\s1-agent-helper.ps1" ${var.s1_console_prefix} ${var.s1_api_key} ${var.s1_site_token_aws} ${var.s1_agent_status}
Rename-Computer -NewName aws-Server2019
Uninstall-WindowsFeature Windows-Defender
$file_name = "Relax.zip"
$download_link = "https://s1demostorageaccount.z13.web.core.windows.net/samples/$file_name"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($download_link, "C:\Users\Administrator\Desktop\$file_name")
echo "s1demo" > "C:\Users\Administrator\Desktop\$\{file_name\}_password.txt"
$file_name = "eicar.com.txt"
$download_link = "https://secure.eicar.org/eicar.com.txt"
$wc2 = New-Object System.Net.WebClient
$wc2.DownloadFile($download_link, "C:\Users\Administrator\Desktop\$file_name")
sleep 3
Restart-Computer -Force
</powershell>
EOF 
}
# Double check on file_name #####################################

resource "aws_security_group" "sg_3389_80" {
  name = "aws-windows-cws-sg1"

  # SSH access from the VPC
  ingress {
    from_port   = 3389
    to_port     = 3389
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


resource "aws_iam_instance_profile" "windows_2019_profile" {
  name = "aws-windows-2019-cws-instance-profile"
  role = aws_iam_role.windows_2019_role.name
}

resource "aws_iam_role" "windows_2019_role" {
  name = "aws-windows-2019-cws-iam-role"
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
    name = "aws-windows-2019-cws-inline-policy"
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


output "windows_2019_EIP" {
  value = aws_instance.windowsInstance.public_ip
}
output "reboot_windows_2019_instance" {
  value = "aws ec2 reboot-instances --instance-ids ${aws_instance.windowsInstance.id}"
}
output "start_windows_2019_instance" {
  value = "aws ec2 start-instances --instance-ids ${aws_instance.windowsInstance.id}"
}
output "stop_windows_2019_instance" {
  value = "aws ec2 stop-instances --instance-ids ${aws_instance.windowsInstance.id}"
}
output "get_windows_2019_public_ip" {
  value = "aws ec2 describe-instances --instance-ids ${aws_instance.windowsInstance.id} | jq -r '.Reservations[].Instances[].PublicIpAddress'"
}

# TODO:  NEED TO MAKE THIS PORTABLE!!! ########################################################################
output "get_windows_2019_rdp_password" {
  value = "aws ec2 get-password-data --instance-id ${aws_instance.windowsInstance.id} --priv-launch-key ~/.ssh/${var.keypair}.pem | jq -r '.PasswordData'"
}
