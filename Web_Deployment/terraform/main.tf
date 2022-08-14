#The main tf file, this will deploy the actual infrastructure to aws.

#Get a list of the avilable AZs in the region you're currently in.
data "aws_availability_zones" "available" {
  state = "available"
}

#Create our own VPC for this deployment along with a public and private subnet for each value in their respective variables.
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

resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_range, 8, each.value + 100)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  map_public_ip_on_launch = true
  tags = {
    Name      = each.key
    Terrafrom = true
  }
}

#An internet gateway will be attached to each public subnet to give them that access.
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
    name        = "public_facing_route_table"
    Description = "Routes traffic from the public subnets to the internet."
    Terraform   = true
  }
}

resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public_subnets]
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

#A nat gateway will take the place of the igw for the private subnets to reach out and install what they need.
resource "aws_eip" "nat_ip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  depends_on    = [aws_subnet.public_subnets]
  subnet_id     = aws_subnet.public_subnets["public_subnet_1"].id
  allocation_id = aws_eip.nat_ip.id
  tags = {
    Name = "web_deployment_nat"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name      = "private_route_table"
    Terraform = true
  }
}

resource "aws_route_table_association" "private" {
  depends_on     = [aws_subnet.private_subnets]
  route_table_id = aws_route_table.private_route_table.id
  for_each       = aws_subnet.private_subnets
  subnet_id      = each.value.id
}

#A security group for the load balancers will only allow http traffic inbound and anything outbound.
resource "aws_security_group" "allow_web_connect_alb" {
  name        = "alb_sg"
  description = "Allow http traffic"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name      = "alb_sg"
    Terraform = true
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#The alb will serve out the load from the public subnets to the instances in private subnets.
resource "aws_lb" "alb" {
  name               = "jlWebDeploymentAlb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web_connect_alb.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]
}

/*The instances themselves will have a similar security group, though more restrictive
as it will only allow http from resources using the alb's security group.
*/
resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Allow http traffic"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name      = "instance_sg"
    Terraform = true
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_web_connect_alb.id]
  }

  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Get the latest amazon linux ami and store it's info.
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

#Create an IAM role and profile for the instance that will allow it to create Session Manager sessions.
resource "aws_iam_role" "instance_role" {
  name = "instance_role"
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
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  tags = {
    Name        = "instance_role"
    Description = "Allows the instance to use session manager."
  }
}

resource "aws_iam_instance_profile" "web_instance_profile" {
  name = "web_instance_profile"
  role = aws_iam_role.instance_role.name
}

/* Although we aren't allowing ssh on these instances, adding an ssh key to instances 
is still best practice and should probably be done regardless*/
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "instance_key_pair"
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "local_sensitive_file" "pem_file" {
  filename        = "instance_priv_key.pem"
  file_permission = "400"
  content         = tls_private_key.private_key.private_key_pem
}

#A launch template will use the ami, profile and security group and launch with some user data to get everything set up.
resource "aws_launch_template" "asg_launch_template" {
  name          = "lt-webdeploy-asg-launchtemplate"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  monitoring {
    enabled = true
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.web_instance_profile.arn
  }
  network_interfaces {
    security_groups = [aws_security_group.instance_sg.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Web_Instance"
    }
  }
  user_data = filebase64("init.sh")
}

#Using this launch template, multiple autoscaling groups will launch instances to it's specifications.
resource "aws_autoscaling_group" "asgs" {
  depends_on        = [aws_nat_gateway.nat_gateway]
  for_each          = var.private_subnets
  name              = join("asg_", [each.value])
  max_size          = 3
  min_size          = 1
  health_check_type = "ELB"
  desired_capacity  = 2
  launch_template {
    id      = aws_launch_template.asg_launch_template.id
    version = "$Latest"
  }
  vpc_zone_identifier = [for subnet in aws_subnet.private_subnets : subnet.id]
}

#These groups will then be hooked up to the load balancer to balance to through a target group and http listener.
resource "aws_lb_target_group" "asg_tg" {
  name     = "autoScalingGroupTg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  tags = {
    Name        = "autoScalingGroupTg"
    Description = "A target group for the listener to point to the appropriate autoscaling groups."
  }
}

resource "aws_autoscaling_attachment" "attach_sg_tg" {
  for_each               = aws_autoscaling_group.asgs
  autoscaling_group_name = aws_autoscaling_group.asgs[each.key].id
  lb_target_group_arn    = aws_lb_target_group.asg_tg.arn
}

resource "aws_lb_listener" "http_to_tg" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg_tg.arn
  }
}

