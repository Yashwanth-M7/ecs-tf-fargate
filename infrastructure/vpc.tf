provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {}
}

resource "aws_vpc" "production_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "production_vpc"
  }
}

############## PUBIC_SUBNET ##############
resource "aws_subnet" "public_subnet_1" {
  cidr_block        = var.public_subnet_1_cidr
  vpc_id            = aws_vpc.production_vpc.id
  availability_zone ="${var.aws_region}a"

  tags = {
    Name = "public_subnet_1"
  } 
}

resource "aws_subnet" "public_subnet_2" {
  cidr_block        = var.public_subnet_2_cidr
  vpc_id            = aws_vpc.production_vpc.id
  availability_zone ="${var.aws_region}b"

  tags = {
    Name = "public_subnet_2"
  } 
}

resource "aws_subnet" "public_subnet_3" {
  cidr_block        = var.public_subnet_3_cidr
  vpc_id            = aws_vpc.production_vpc.id
  availability_zone ="${var.aws_region}c"

  tags = {
    Name = "public_subnet_3"
  } 
}

############## PRIVATE_SUBNET ##############
resource "aws_subnet" "private_subnet_1" {
  cidr_block        = var.private_subnet_1_cidr
  vpc_id            = aws_vpc.production_vpc.id
  availability_zone ="${var.aws_region}a"

  tags = {
    Name = "private_subnet_1"
  } 
}

resource "aws_subnet" "private_subnet_2" {
  cidr_block        = var.private_subnet_2_cidr
  vpc_id            = aws_vpc.production_vpc.id
  availability_zone ="${var.aws_region}b"

  tags = {
    Name = "private_subnet_2"
  } 
}

resource "aws_subnet" "private_subnet_3" {
  cidr_block        = var.private_subnet_3_cidr
  vpc_id            = aws_vpc.production_vpc.id
  availability_zone ="${var.aws_region}c"

  tags = {
    Name = "private_subnet_3"
  } 
}

##Public_Route_Tables############################

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.production_vpc.id

  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table_association" "public_subnet_1_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet_1.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet_2.id
}

resource "aws_route_table_association" "public_subnet_3_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet_3.id
}

##Private_Route_Tables##########################

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.production_vpc.id

  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route_table_association" "private_subnet_1_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id = aws_subnet.private_subnet_1.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id = aws_subnet.private_subnet_2.id
}

resource "aws_route_table_association" "private_subnet_3_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id = aws_subnet.private_subnet_3.id
}

##Elastic_IP

resource "aws_eip" "elastic_ip_for_nat_gw" {
  domain                    = "vpc"
  associate_with_private_ip = "10.10.0.25"

  tags = {
    Name = "Production_EIP"
  }
  depends_on = [ aws_internet_gateway.production_igw ]
}

##Internet_GW

resource "aws_internet_gateway" "production_igw" {
  vpc_id = aws_vpc.production_vpc.id
  tags = {
    Name = "Production_IGW"
  }
}

resource "aws_route" "int_gw_route" {
  route_table_id = aws_route_table.public_route_table.id
  gateway_id = aws_internet_gateway.production_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

##NAT_Gateway

resource "aws_nat_gateway" "production_nat_gw" {
  allocation_id = aws_eip.elastic_ip_for_nat_gw.id
  subnet_id = aws_subnet.public_subnet_1.id

  tags = {
    Name = "Production_NAT_GW"
  }
  depends_on = [ aws_eip.elastic_ip_for_nat_gw ]
}

resource "aws_route" "nat_gw_route" {
  route_table_id = aws_route_table.private_route_table.id
  nat_gateway_id = aws_nat_gateway.production_nat_gw.id
  destination_cidr_block = "0.0.0.0/0"
}

