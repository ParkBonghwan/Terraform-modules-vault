output "vpc_cidr" {
  value = var.create_vpc ? element(concat(aws_vpc.main.*.cidr_block, tolist([])), 0) : var.vpc_cidr
}

output "vpc_id" {
  value = var.create_vpc ? element(concat(aws_vpc.main.*.id, tolist([])), 0) : var.vpc_id
}

output "subnet_public_ids" {
  value = aws_subnet.public.*.id
}

output "subnet_private_ids" {
  value = aws_subnet.private.*.id
}