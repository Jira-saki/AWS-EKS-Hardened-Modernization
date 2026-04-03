# 1. Base VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "main-vpc"
    Project = "Modernization"
  }
}

# 2. 3-Tier  Subnets (Public, Private, Data)
# 2 AZs (ap-northeast-1a, 1c) finops but HA
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
    Project = "Modernization"
    Tier = "Public"
    "kubernetes.io/role/elb" = "1" # Heart of EKS
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  # Offset the index by the number of AZs to avoid overlapping with Public Subnets
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
    Project = "Modernization"
    Tier = "Private"
    "kubernetes.io/role/internal-elb" = "1" # Heart of EKS
  }
}

resource "aws_subnet" "data" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  # Offset by 2x length to avoid overlapping with Public and Private tiers
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + length(var.availability_zones) * 2)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "data-subnet-${count.index + 1}"
    Project = "Modernization"
    Tier = "Data"
  }
}

# 3. Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
    Project = "Modernization"
  }
}

# 4. Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = { Name = "nat-eip"}
}

# 5. NAT Gateway ( in Public Subnet )
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public[0].id # Place in the first public subnet 1

  tags = {
    Name = "main-nat"
  }

  # wait for IGW finished first
  depends_on = [ aws_internet_gateway.main ]
}

# 6. Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "public-rt" }
}

# 7. Private Route Table ( use for Private / Data subnets)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = { Name = "private-rt" }
}

# 8. Route Table Associations ( connect Subnets to Route Tables )
# for Public
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# for Private
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# for Data ( Database will not go outside, for Patching; use NAT)
resource "aws_route_table_association" "data" {
  count = length(var.availability_zones)
  subnet_id = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.private.id
} 