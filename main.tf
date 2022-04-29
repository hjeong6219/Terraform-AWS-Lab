provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
}

resource "aws_subnet" "pub_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.pub_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.igw]
}

resource "aws_subnet" "priv_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.priv_subnet_cidr
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "intra_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.intra_subnet_cidr
  availability_zone       = "${var.region}c"
  map_public_ip_on_launch = false
}

resource "aws_route_table" "pub_subnet_route_table" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "priv_subnet_route_table" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "intra_subnet_route_table" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_eip" "eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "pub_nat" {
  subnet_id  = aws_subnet.pub_subnet.id
  allocation_id = aws_eip.eip.id
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "pub_subnet_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.pub_subnet_route_table.id
}

resource "aws_route" "priv_subnet_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.pub_nat.id
  route_table_id         = aws_route_table.priv_subnet_route_table.id
}

resource "aws_route_table_association" "pub_subnet_route_table_association" {
  subnet_id      = aws_subnet.pub_subnet.id
  route_table_id = aws_route_table.pub_subnet_route_table.id
}

resource "aws_route_table_association" "priv_subnet_route_table_association" {
  subnet_id      = aws_subnet.priv_subnet.id
  route_table_id = aws_route_table.priv_subnet_route_table.id
}
