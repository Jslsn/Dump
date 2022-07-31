/*The variables tf file, this contains the information that may vary on deployment 
and is used to create dynamic resources.*/
variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "vpc_name" {
  type    = string
  default = "web_deployment_jl"
}

variable "vpc_cidr_range" {
  type    = string
  default = "10.1.0.0/16"
}

variable "public_subnet" {
  type    = string
  default = "public_subnet_1"
}

variable "private_subnets" {
  default = {
    "private_subnet_1" = 1
    "private_subnet_2" = 2
  }
}

