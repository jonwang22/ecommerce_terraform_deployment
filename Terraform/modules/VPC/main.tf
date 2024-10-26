##################################################
### VPC ###
##################################################
# Creating our Custom VPC
resource "aws_vpc" "wl5vpc" {
  cidr_block       = "10.0.0.0/20"
  instance_tenancy = "default"

  tags = {
    Name = "wl5vpc"
  }
}

##################################################
### SUBNETS ###
##################################################
# Creating Public Subnet in USE1a
resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.wl5vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "WL5 Public Subnet 1"
  }
}

# Creating Public Subnet in USE1b
resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.wl5vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "WL5 Public Subnet 2"
  }
}

# Creating Private Subnet in USE1a
resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.wl5vpc.id
  availability_zone = "us-east-1a"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "WL5 Private Subnet 1"
  }
}

# Creating Private Subnet in USE1b
resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.wl5vpc.id
  availability_zone = "us-east-1a"
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "WL5 Private Subnet 2"
  }
}

##################################################
### GATEWAYS ###
##################################################
# Creating Internet Gateway and associating the IGW to the Custom VPC via VPC ID
resource "aws_internet_gateway" "wl5igw" {
  vpc_id = aws_vpc.wl5vpc.id

  tags = {
    Name = "WL5 Internet Gateway"
  }
}

# Creating EIP for NAT Gateway 1
resource "aws_eip" "wl5_nat_eip_1" {
  domain = "vpc"

  tags = {
    Name = "WL5 NAT EIP 1"
  }
}

# Creating NAT Gateway for Private Subnet 1 to use.
resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.wl5_nat_eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "WL5 NAT Gateway 1"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.wl5igw]
}

# Creating EIP for NAT Gateway 2
resource "aws_eip" "wl5_nat_eip_2" {
  domain = "vpc"

  tags = {
    Name = "WL5 NAT EIP 2"
  }
}

# Creating NAT Gateway for Private Subnet 2 to use.
resource "aws_nat_gateway" "nat_gateway_2" {
  allocation_id = aws_eip.wl5_nat_eip_2.id
  subnet_id     = aws_subnet.public_subnet_2.id

  tags = {
    Name = "WL5 NAT Gateway 2"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.wl5igw]
}

##################################################
### ROUTE TABLES ###
##################################################
# Creating a custom Route Table for Public Subnet, assigning route for IGW
resource "aws_route_table" "public_routetable" {
  vpc_id = aws_vpc.wl5vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wl5igw.id
  }

  tags = {
    Name = "WL5 Public Route Table"
  }
}

# Creating a Private Route Table for Private Subnet 1
resource "aws_route_table" "private_routetable_1" {
  vpc_id = aws_vpc.wl5vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_1.id
  }

  tags = {
    Name = "WL5 Private Route Table 1"
  }
}

# Creating a Private Route Table for Private Subnet 2
resource "aws_route_table" "private_routetable_2" {
  vpc_id = aws_vpc.wl5vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_2.id
  }

  tags = {
    Name = "WL5 Private Route Table 2"
  }
}
##################################################
### ROUTE TABLES ASSOCIATIONS ###
##################################################
# Associating Public Subnets to Public Route Table
resource "aws_route_table_association" "Public_Subnet_Association1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_routetable.id
}
resource "aws_route_table_association" "Public_Subnet_Association2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_routetable.id
}

# Associating Private Subnet 1 to Private Route Table 1
resource "aws_route_table_association" "Private_Subnet_1_Association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_routetable_1.id
}

# Associating Private Subnet 2 to Private Route Table 2
resource "aws_route_table_association" "Private_Subnet_2_Association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_routetable_2.id
}