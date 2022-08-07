/*The variables tf file, this contains the information that may vary on deployment 
and is used to create dynamic resources.*/

#Set the region, vpc name and cidr range along with names for the subnets through a default value that can be overwritten.
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

variable "public_subnets" {
  default = {
    "public_subnet_1" = 1
    "public_subnet_2" = 2
  }
}

variable "private_subnets" {
  default = {
    "private_subnet_1" = 1
    "private_subnet_2" = 2
  }
}

#Set the domain name through a variable, this will not have a default as it must vary.
variable "alb_domain" {
  type        = string
  description = "Add the domain for your certificate."
}
