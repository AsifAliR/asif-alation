variable "aws_access_key" {
  type    = string
}

variable "aws_secret_key" {
  type    = string
}

variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/terraform.pub
DESCRIPTION
}

variable "key_name" {
  description = "Desired name of AWS key pair"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-2"
}

variable "aws_az1" {
  description = "AWS AZ to launch servers."
  default     = "us-east-2a"
}

variable "aws_az2" {
  description = "AWS AZ to launch servers."
  default     = "us-east-2b"
}

# Ubuntu AMI
variable "aws_amis" {
  default = {
    us-east-2 = "ami-0e82959d4ed12de3f"
  }
}