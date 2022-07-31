#The main tf file, this will deploy the actual infrastructure to aws.

data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_region" "current" {}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_range
  tags = {
    Name        = var.vpc_name
    Description = "VPC for Jordan L's basic Website."
    Environment = "jl_web_vpc_env"
    Terraform   = "True"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr_range, 8, each.value)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]
  tags = {
    Name      = each.key
    Terrafrom = true
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_range, 8, 201)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[1]
  map_public_ip_on_launch = true
  tags = {
    Name      = var.public_subnet
    Terrafrom = true
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "jl_web_deployment_igw"
    Description = "Gives the vpc an out to the internet."
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name        = "public_facing_route_table"
    Description = "Creates a route table to route traffic from the public subnet to the internet."
    Terraform   = true
  }
}

resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public_subnet]
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet.id
}



