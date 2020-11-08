terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.aws_az1
  map_public_ip_on_launch = true
}

resource "aws_subnet" "secondary" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.aws_az2
  map_public_ip_on_launch = true
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "lb" {
  name        = "asif_lb"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.default.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "asif_example"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.default.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Ping test from anywhere
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "web" {
  name               = "asif-lb"
  internal           = false
  load_balancer_type = "application"

  subnets         = [aws_subnet.default.id, aws_subnet.secondary.id]
  security_groups = [aws_security_group.lb.id] 
}

resource "aws_lb_target_group" "test" {
  name     = "alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_lb.web.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.test.id
    type             = "forward"
  }
}

resource "aws_alb_target_group_attachment" "tg_attach" {
  count = 2
  target_group_arn = aws_lb_target_group.test.id
  port = 80
  target_id = aws_instance.web[count.index].id
}


resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}


resource "aws_eip" "lb" {
  count = 2
  instance = aws_instance.web[count.index].id
  vpc      = true
}

resource "aws_instance" "web" {

  # Number of instances to be provisioned
  count = 2
 
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
   
  connection {
    type = "ssh"
    # The default username for our AMI
    user = "ubuntu"
    host = self.public_ip
    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region we specified
  ami = var.aws_amis[var.aws_region]

  # The name of our SSH keypair we created above.
  key_name = aws_key_pair.auth.id

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [aws_security_group.default.id]

  # We're going to launch into the same subnet as our LB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  
  subnet_id = aws_subnet.default.id
    
  depends_on = [
    aws_alb_listener.front_end,
    aws_subnet.default,
  ]
}
