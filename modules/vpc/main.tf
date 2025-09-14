resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project}-vpc" }
}

data "aws_availability_zones" "available" {}

locals { azs = slice(data.aws_availability_zones.available.names, 0, var.az_count) }

resource "aws_subnet" "public" {
  for_each = toset(local.azs)
  vpc_id   = aws_vpc.this.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, index(local.azs, each.value))
  availability_zone = each.value
  map_public_ip_on_launch = true
  tags = { Name = "${var.project}-public-${each.value}" }
}

resource "aws_subnet" "private" {
  for_each = toset(local.azs)
  vpc_id   = aws_vpc.this.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, index(local.azs, each.value)+10)
  availability_zone = each.value
  tags = { Name = "${var.project}-private-${each.value}" }
}
