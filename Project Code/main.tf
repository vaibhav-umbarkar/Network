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
    tags = {
        Name = "nat-eip-1"
    }
}

resource "aws_eip" "nat_eip_2" {
  depends_on = [aws_internet_gateway.main_igw]
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


# Create Security Group for Private Subnets
resource "aws_security_group" "private_sg"{
    description = "Security Group for Private Subnets"
    vpc_id = aws_vpc.main_vpc.id

    ingress = {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Allow All SSH
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"] # Allow All Outbound
    }

    tags = {
        Name = "Private-SG"
    }
}


# Create 2 EC2 Instance in Private Subnets
resource "aws_instance" "private_instance_1"{
    ami = var.ami_id
    instance_type = var.instance_type
    subnet_id = aws_subnet.private_subnet_1.id
    vpc_security_group_ids = [aws_security_group.private_sg.id]
    tags = {
        Name = "Private_Instance-1"
    }
}

resource "aws_instance" "private_instance_2"{
    ami = var.ami_id
    instance_type = var.instance_type
    subnet_id = aws_subnet.private_subnet_2.id
    vpc_security_group_ids = [aws_security_group.private_sg.id]
    tags = {
        Name = "Private-Instance-2"
    }
}
