# AWS Region
variable "region" {
  description = "AWS Region for Deploy Resources"
  default = "eu-north-1"
}

# AMI ID for EC2 Instances
variable "ami_id"{
    description = "Ubuntu 24.04 LTS AMI ID"
    default = "ami-0a716d3f3b16d290c"
}

# Instance Type 
variable "instance_type"{
    description = "Instance Type"
    default = "t3.micro"
}