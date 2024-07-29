#variables.tf
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_name" {
  type    = string
  default = "linkedin-counter-vpc"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet1_cidr_block" {
  description = "The CIDR block for subnet 1"
  default     = "10.0.1.0/24"
}

variable "subnet2_cidr_block" {
  description = "The CIDR block for subnet 2"
  default     = "10.0.2.0/24"
}
variable "private_subnets" {
  default = {
    "private_subnet_1" = 1
    "private_subnet_2" = 2
    "private_subnet_3" = 3
  }
}

variable "public_subnets" {
  default = {
    "public_subnet_1" = 1
    "public_subnet_2" = 2
    "public_subnet_3" = 3
  }
}


variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  default     = "ami-01fccab91b456acc2"
}

variable "instance_type" {
  description = "The type of instance to use"
  default     = "t2.micro"
}


variable "lambda_function_name" {
  default = "WebsiteVisitCounter"
}

variable "dynamodb_table_name" {
  default = "LinkedinVisitTable"
}

variable "lambda_handler" {
  default = "index.handler"
}

variable "runtime" {
  default = "python3.8"
}


variable "target_url" {
  default = "https://www.linkedin.com/in/ameyermunoz/"
}

