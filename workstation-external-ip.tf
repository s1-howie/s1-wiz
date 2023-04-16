#
# Workstation External IP
#
# This configuration easily fetches the external IP of your local workstation to
# configure inbound Security Group/Firewall access. 
# 
# NOTE: This assumes that you'll be using the same machine to access instances
# as was used to execute this terraform template.
#

data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}

# Override with variable or hardcoded value if necessary
locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.response_body)}/32"
}
