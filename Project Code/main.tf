# AWS Provider Configuration
provider "aws"{
  # Configuration options
    region = var.region
}

# Create VPC
resource "aws_vpc" "main_vpc"{
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "Main-VPC"
    }
}

# Create 4 Subnets in Different AZs (Private 2, Public 2)
resource "aws_subnet" "public_subnet_1"{
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "eu-north-1a"
    tags = {
        Name = "Public-Subnet-1"
    }
}

resource "aws_subnet" "private_subnet_1"{
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "eu-north-1a"
    tags = {
        Name = "Private-Subnet-1"
    }
}

resource "aws_subnet" "public_subnet_2"{
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = true
    availability_zone = "eu-north-1b"
    tags = {
        Name = "Public-Subnet-2"
    }
}

resource "aws_subnet" "private_subnet_2"{
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "eu-north-1b"
    tags = {
        Name = "Private-Subnet-2"
    }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main_igw"{
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "Main-IGW"
    }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_eip_1" {
    depends_on = [aws_internet_gateway.main_igw]
    domain = "vpc"
    tags = {
        Name = "nat-eip-1"
    }
}

resource "aws_eip" "nat_eip_2" {
  depends_on = [aws_internet_gateway.main_igw]
    domain = "vpc"
    tags = {
        Name = "nat-eip-2"
    }
}

# NAT Gateways (placed in public subnets)
resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = { Name = "nat-1" }
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_subnet_2.id
  tags = { Name = "nat-2" }
}

# Create Route Table for Public & Private Subnets
resource "aws_route_table" "public_rt"{
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main_igw.id
    }
    tags = {
        Name = "Public-Route-Table"
    }
}

resource "aws_route_table" "private_rt_1"{
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "Private-Route-Table-1"
    }
}

resource "aws_route_table" "private_rt_2"{
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "Private-Route-Table-2"
    }
}

# Create NAT Gateway in Public Subnet
resource "aws_route" "private_nat_1"{
    route_table_id = aws_route_table.private_rt_1.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
}

resource "aws_route" "private_nat_2"{
    route_table_id = aws_route_table.private_rt_2.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
}


# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public_subnet_association_1"{
    route_table_id = aws_route_table.public_rt.id
    subnet_id = aws_subnet.public_subnet_1.id
}

resource "aws_route_table_association" "public_subnet_association_2"{
    route_table_id = aws_route_table.public_rt.id
    subnet_id = aws_subnet.public_subnet_2.id
}

resource "aws_route_table_association" "private_subnet_association_1"{
    route_table_id = aws_route_table.private_rt_1.id
    subnet_id = aws_subnet.private_subnet_1.id
}

resource "aws_route_table_association" "private_subnet_association_2"{
    route_table_id = aws_route_table.private_rt_2.id
    subnet_id = aws_subnet.private_subnet_2.id
}

# security group for ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main_vpc.id
  description = "Security group for ALB"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB-SG"
  }
}

# Security group for Private Instances
resource "aws_security_group" "private_sg" {
    vpc_id = aws_vpc.main_vpc.id
    description = "Allow traffic from ALB"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.alb_sg.id] # Allow ALB traffic only
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = [aws_security_group.alb_sg.id] # Allow ALB traffic only
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Private-SG"
    }
}

# Application Load Balancer
resource "aws_lb" "app_alb" {
    name = "app-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_sg.id]
    subnets = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    tags = {
        Name = "App-ALB"
    }
}

# Target Group for ALB
resource "aws_lb_target_group" "app_tg" {
    name = "app-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.main_vpc.id
    
    health_check {
        path                = "/"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 3
        unhealthy_threshold = 3
        matcher             = "200"
        protocol            = "HTTP"
    }


    tags = {
        Name = "App-TG"
    }
}

# Register EC2 instances to target group
resource "aws_lb_target_group_attachment" "tg_attach_1" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id = aws_instance.private_instance_1.id
  port = 80
}

resource "aws_lb_target_group_attachment" "tg_attach_2" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id = aws_instance.private_instance_2.id
  port = 80
}

# ALB Listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Create 2 EC2 Instance in Private Subnets
resource "aws_instance" "private_instance_1"{
    ami = var.ami_id
    instance_type = var.instance_type
    subnet_id = aws_subnet.private_subnet_1.id
    vpc_security_group_ids = [aws_security_group.private_sg.id]
    
    associate_public_ip_address = true

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y || apt-get update -y
                sudo apt install -y nginx || apt-get install -y nginx
                sudo systemctl start nginx
                sudo systemctl enable nginx
                echo "Hello from Private Instance 1" > /var/www/html/index.html
                EOF
    
    tags = {
        Name = "Private_Instance-1"
    }
}

resource "aws_instance" "private_instance_2"{
    ami = var.ami_id
    instance_type = var.instance_type
    subnet_id = aws_subnet.private_subnet_2.id
    vpc_security_group_ids = [aws_security_group.private_sg.id]

    associate_public_ip_address = true

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y || apt-get update -y
                sudo apt install -y nginx || apt-get install -y nginx
                sudo systemctl start nginx
                sudo systemctl enable nginx
                echo "Hello from Private Instance 2" > /var/www/html/index.html
                EOF

    tags = {
        Name = "Private-Instance-2"
    }
}
