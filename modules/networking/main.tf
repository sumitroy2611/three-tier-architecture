/*
*  Terraform network configuration
*/

/*
*  VPC configuration
*/

# Creating VPC
resource "aws_vpc" "demovpc" {
    cidr_block       = "${var.vpc_cidr}.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy = "default"
    tags = {
    Name = "Demo VPC"
    }
}

/*
* Internet Gateway Configuration
*/
# Internet Gateway to give internet access to application servers
resource "aws_internet_gateway" "demogateway" {
  vpc_id = "${aws_vpc.demovpc.id}"
  tags = {
    Name = "Demo IGW"
  }
}

# Returns the availability zone as per the region provided
data "aws_availability_zones" "available" {
  state = "available"
}

/*
*  Subnet configuration
*/

# Public subnet1 for web server 
resource "aws_subnet" "public_subnets" {
  count                   = var.public_sn_count
  vpc_id                  = "${aws_vpc.demovpc.id}"
  cidr_block              = "${var.vpc_cidr}.${10 + count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Public subnet ${count.index + 1}"
  }
}

# Private subnet for application server 
resource "aws_subnet" "private_subnets" {
  count                   = var.private_sn_count
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block              = "${var.vpc_cidr}.${20 + count.index}.0/24"
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Private subnet ${count.index + 1}"
  }
}

# Private subnet for Database server 
resource "aws_subnet" "private_subnets_db" {
  count                   = var.private_sn_count
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block              = "${var.vpc_cidr}.${40 + count.index}.0/24"
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "DB private subnet ${count.index + 1}"
  }
}

/*
* NAT Gateway and EIP configuration
*/

#NAT Gateway config
resource "aws_nat_gateway" "ngw" {
  allocation_id     = var.allocation_id
  subnet_id         = aws_subnet.public_subnets[1].id
}

/*
* Route table configuration
*/

#Public route table config
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.demovpc.id

  tags = {
    Name = "Public route table"
  }
}

#Public route config
resource "aws_route" "default_public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.demogateway.id
}

#Public route table association
resource "aws_route_table_association" "rt_public_assoc" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.public_subnets.*.id[count.index]
  route_table_id = aws_route_table.public_rt.id
}

#Private route table config
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.demovpc.id
  
  tags = {
    Name = "Private route table"
  }
}

#Private route config
resource "aws_route" "default_private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.ngw.id
}

#Private route table association
resource "aws_route_table_association" "rt_private_assoc" {
  count          = var.private_sn_count
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_subnets.*.id[count.index]
}

/*
* Security Group configuration
*/

resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Allow SSH Inbound Traffic From Set IP"
  vpc_id      = aws_vpc.demovpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.access_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for the loadbalancer
resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow Inbound HTTP Traffic"
  vpc_id      = aws_vpc.demovpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security group for web server
resource "aws_security_group" "frontend_app_sg" {
  name        = "frontend_app_sg"
  description = "Allow SSH inbound traffic from Bastion, and HTTP inbound traffic from loadbalancer"
  vpc_id      = aws_vpc.demovpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security group for app server
resource "aws_security_group" "backend_app_sg" {
  name        = "backend_app_sg"
  vpc_id      = aws_vpc.demovpc.id
  description = "Allow Inbound HTTP from FRONTEND APP, and SSH inbound traffic from Bastion"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security group for rds
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow MySQL Port Inbound Traffic from Backend App Security Group"
  vpc_id      = aws_vpc.demovpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*
* Subnet group configuration
*/

# Subnet group for database
resource "aws_db_subnet_group" "rds_subnetgroup" {
  count      = var.db_subnet_group == true ? 1 : 0
  name       = "rds_subnetgroup"
  subnet_ids = [aws_subnet.private_subnets_db[0].id, aws_subnet.private_subnets_db[1].id]

  tags = {
    Name = "Demo rds sng"
  }
}
