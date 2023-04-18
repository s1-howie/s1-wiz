variable "aws_region" {
  description = "The preferred AWS Region in which to launch the resources outlined in this template."
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "The AWS Access Key with which to launch the resources outlined in this template."
}

variable "aws_secret_access_key" {
  description = "The AWS Secret Access Key with which to launch the resources outlined in this template."
}

variable "ec2_instance_type" {
  description = "AWS Instance Type to use for the EC2 instance."
  default     = "t3.medium"
}

variable "tags" {
  description = "tags to assign to the resource(s)."
  default     = { s1-demo = "true", environment = "test" }
}

# variable "ssh_key_name" {
#   type        = string
#   description = "The SSH key pair name in EC2."
# }

variable "s1_site_token_aws" {
  description = "The Sentinel One Site Token that the K8s agent will use when communicating with the S1 portal."
}

variable "keypair" {
  description = "EC2 Key Pair"
  default     = "s1"
}

variable "s1_console_prefix" {
  description = "The prefix of the SentinelOne Management Console."
  default     = "usea1-purple"
}

variable "s1_api_key" {
  description = "The SentinelOne API key to authenticate to the SentinelOne Management Console (for downloading the agent package)."
}

variable "s1_agent_status" {
  description = "The version status of the agent to deploy.  Valid values are 'ea' or 'ga'."
  default     = "ga"
}