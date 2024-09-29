provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {}
}

resource "aws_vpc" "production-vpc" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "production-vpc"
  }
}

############## PUBIC_SUBNET ##############
resource "aws_subnet" "public-subnet-1" {
  cidr_block        = var.public-subnet-1-cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone ="${var.aws_region}a"

  tags {
    Name = "public-subnet-1"
  } 
}

resource "aws_subnet" "public-subnet-2" {
  cidr_block        = var.public-subnet-2-cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone ="${var.aws_region}b"

  tags {
    Name = "public-subnet-2"
  } 
}

resource "aws_subnet" "public-subnet-3" {
  cidr_block        = var.public-subnet-3-cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone ="${var.aws_region}c"

  tags {
    Name = "public-subnet-3"
  } 
}

############## PRIVATE_SUBNET ##############
resource "aws_subnet" "private-subnet-1" {
  cidr_block        = var.private-subnet-1-cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone ="${var.aws_region}a"

  tags {
    Name = "private-subnet-1"
  } 
}

resource "aws_subnet" "private-subnet-2" {
  cidr_block        = var.private-subnet-2-cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone ="${var.aws_region}b"

  tags {
    Name = "private-subnet-2"
  } 
}

resource "aws_subnet" "private-subnet-3" {
  cidr_block        = var.private-subnet-3-cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone ="${var.aws_region}c"

  tags {
    Name = "private-subnet-3"
  } 
}

##Public_Route_Tables############################

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.production-vpc.id

  tags {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public-subnet-1-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-1.id
}

resource "aws_route_table_association" "public-subnet-2-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-2.id
}

resource "aws_route_table_association" "public-subnet-3-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-3.id
}

##Private_Route_Tables##########################

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.production-vpc.id

  tags {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private-subnet-1-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id = aws_subnet.private-subnet-1.id
}

resource "aws_route_table_association" "private-subnet-2-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id = aws_subnet.private-subnet-2.id
}

resource "aws_route_table_association" "private-subnet-3-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id = aws_subnet.private-subnet-3.id
}

##Internet-GW

resource "aws_internet_gateway" "production-igw" {
  vpc_id = aws_vpc.production-vpc.id
  tags = {
    Name = "Production-IGW"
  }
}

##Elastic-IP

resource "aws_eip" "elastic-ip-for-nat-gw" {
  vpc = true
  associate_with_private_ip = "10.10.0.25"

  tags {
    Name = "Production-EIP"
  }
  depends_on = [ aws_internet_gateway.production-igw ]
}

##NAT-Gateway

resource "aws_nat_gateway" "production-nat-gw" {
  allocation_id = aws_eip.elastic-ip-for-nat-gw.id
  subnet_id = aws_subnet.public-subnet-1.id

  tags {
    Name = "Production-NAT-GW"
  }
  depends_on = [ aws_eip.elastic-ip-for-nat-gw ]
}

##gateway association
resource "aws_route" "nat-gw-route" {
  route_table_id = aws_route_table.public-route-table.id
  nat_gateway_id = aws_nat_gateway.production-nat-gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "int-gw-route" {
  route_table_id = aws_route_table.public-route-table.id
  gateway_id = aws_internet_gateway.production-igw.id
  destination_cidr_block = "0.0.0.0/0"
}