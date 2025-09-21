# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project}-vpc" }
}

# AZs
data "aws_availability_zones" "available" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

# Public subnets
resource "aws_subnet" "public" {
  for_each                = toset(local.azs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, index(local.azs, each.value))
  availability_zone       = each.value
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project}-public-${each.value}" }
}

# Private subnets
resource "aws_subnet" "private" {
  for_each          = toset(local.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(local.azs, each.value) + 10)
  availability_zone = each.value
  tags              = { Name = "${var.project}-private-${each.value}" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project}-igw" }
}

# Public route table + route to IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project}-rt-public" }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Locals to reuse IDs
locals {
  public_subnet_ids  = [for s in aws_subnet.public : s.id]
  private_subnet_ids = [for s in aws_subnet.private : s.id]
}

# NAT (OPTIONAL – comment for $0 cost, uncomment when you want to demo)
#resource "aws_eip" "nat" {
# domain = "vpc"
#tags   = { Name = "${var.project}-nat-eip" }
#}
#resource "aws_nat_gateway" "nat" {
##allocation_id = aws_eip.nat.id
#subnet_id     = local.public_subnet_ids[0]
# tags          = { Name = "${var.project}-nat" }
# depends_on    = [aws_internet_gateway.igw]
#}

#resource "aws_route" "private_default" {
# route_table_id         = aws_route_table.private.id
# destination_cidr_block = "0.0.0.0/0"
# nat_gateway_id    terraform plan | sed -n '1,120p'
#    = aws_nat_gateway.nat.id
#}

# Free fallback private route table (no internet)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project}-rt-private" }
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
