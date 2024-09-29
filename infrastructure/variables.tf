variable "aws_region" {
  default = "ap-south-1"
}

variable "vpc_cidr" {
  default = "10.10.0.0/16"  
}

variable "public-subnet-1-cidr" {
  description = "CIDR Block for Public Subnet 1"
}

variable "public-subnet-2-cidr" {
  description = "CIDR Block for Public Subnet 2"
}

variable "public-subnet-3-cidr" {
  description = "CIDR Block for Public Subnet 3"
}

variable "private-subnet-1-cidr" {
  description = "CIDR Block for Private Subnet 1"
}

variable "private-subnet-2-cidr" {
  description = "CIDR Block for Private Subnet 2"
}

variable "private-subnet-3-cidr" {
  description = "CIDR Block for Private Subnet 3"
}

