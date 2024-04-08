data "aws_availability_zones" "main" {}

################################################################################
# aws_vpc 생성
# count는 조건문으로, "var.create", "var.create_vpc" 모두 true 일 때 생성
################################################################################
resource "aws_vpc" "main" {
  count = var.create && var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(var.tags, { "Name" = format("%s", var.name) })
}

################################################################################
# aws_subnet 생성
# count는 조건문으로, "var.create" true이면 "var.vpc_cidrs_public" 길이만큼 생성
################################################################################
resource "aws_subnet" "public" {
  count = var.create ? length(var.vpc_cidrs_public) : 0

  vpc_id                  = var.create_vpc ? aws_vpc.main[0].id : var.vpc_id
  availability_zone       = element(data.aws_availability_zones.main.names, count.index)
  cidr_block              = element(var.vpc_cidrs_public, count.index)
  map_public_ip_on_launch = true

  tags = merge(var.tags, { "Name" = format("%s-public-%d", var.name, count.index + 1) })
}

################################################################################
# aws_subnet 생성
# count는 조건문으로, "var.create" 값이 true이고 "var.vpc_cidrs_public" 이 존재할 때 생성
################################################################################
resource "aws_internet_gateway" "main" {
  count  = var.create ? 1 : 0
  vpc_id = var.create_vpc ? aws_vpc.main[0].id : var.vpc_id

  tags = merge(var.tags, { "Name" = format("%s", var.name) })
}

resource "aws_route_table" "public" {
  count  = var.create ? 1 : 0
  vpc_id = var.create_vpc ? aws_vpc.main[0].id : var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[count.index].id
  }

  tags = merge(var.tags, { "Name" = format("%s-public", var.name) })
}

resource "aws_route_table_association" "public" {
  count = var.create ? length(var.vpc_cidrs_public) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_eip" "nat" {
  count = var.create && var.nat_count != "0" ? var.nat_count : length(var.vpc_cidrs_public)
  vpc   = true

  tags = merge(var.tags, { "Name" = format("%s-%d", var.name, count.index + 1) })
}

resource "aws_nat_gateway" "nat" {
  count = var.create && var.nat_count != "0" ? var.nat_count : length(var.vpc_cidrs_public)

  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = merge(var.tags, { "Name" = format("%s-%d", var.name, count.index + 1) })
}

resource "aws_subnet" "private" {
  count = var.create ? length(var.vpc_cidrs_private) : 0

  vpc_id                  = var.create_vpc ? aws_vpc.main[0].id : var.vpc_id
  availability_zone       = element(data.aws_availability_zones.main.names, count.index)
  cidr_block              = element(var.vpc_cidrs_private, count.index)
  map_public_ip_on_launch = false

  tags = merge(var.tags, { "Name" = format("%s-private-%d", var.name, count.index + 1) })
}

resource "aws_route_table" "private_subnet" {
  count = var.create ? length(var.vpc_cidrs_private) : 0

  vpc_id = var.create_vpc ? aws_vpc.main[0].id : var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat.*.id, count.index)
  }

  tags = merge(var.tags, { "Name" = format("%s-private-%d", var.name, count.index + 1) })
}

resource "aws_route_table_association" "private" {
  count = var.create ? length(var.vpc_cidrs_private) : 0

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private_subnet.*.id, count.index)
}


