variable "region" {
    type = string
    description = "AWS Region"
    default = "us-east-1"
}


variable "az_a" {
    type = string
    description = "Availability Zones"
    default = "us-east-1a"
}

variable "az_b" {
    type = string
    description = "Availability Zones"
    default = "us-east-1b"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}   

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"

}


variable "private_subnet_cidr_a" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"

}

variable "private_subnet_cidr_b" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.0.3.0/24"

}



variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "Name of the existing key pair to use for EC2 instances"
  type        = string
  default     = "ansible-key"
}


variable "ami_id"{
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-080c353f4798a202f"  # Amazon Linux 2 AMI in us-east-1
}


variable "worker_count" {
  description = "Number of worker nodes to create"
  type        = number
  default     = 3
}

variable "private_key_path" {
  description = "path of the .pem file"
  type        = string
  default     = "./privatekey.pem"
}