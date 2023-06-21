# Security Group 
resource "aws_security_group" "vault_server" {
  count       = var.create ? 1 : 0
  name_prefix = var.name
  description = "Security Group for ${var.name} Vault"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "vault_client_traffic" {
  count             = var.create ? 1 : 0
  security_group_id = aws_security_group.vault_server[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8200
  to_port           = 8200
  cidr_blocks       = var.cidr_blocks
}

resource "aws_security_group_rule" "vault_cluster_traffic" {
  count             = var.create ? 1 : 0
  security_group_id = aws_security_group.vault_server[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8201
  to_port           = 8201
  cidr_blocks       = var.cidr_blocks
}

resource "aws_security_group_rule" "outbound_tcp" {
  count             = var.create ? 1 : 0
  security_group_id = aws_security_group.vault_server[count.index].id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault_bastion_traffic" {
  count             = var.create ? 1 : 0
  security_group_id = aws_security_group.vault_server[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = var.cidr_blocks
}

##---------------------------------------------------------------------------------------
# Consul Backend 를 사용할 경우에 대한 고려 추가 

resource "aws_security_group_rule" "consul_client_traffic" {
  count             = var.create && var.use_consul ? 1 : 0
  security_group_id = aws_security_group.vault_server[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8500
  to_port           = 8500
  cidr_blocks       = var.cidr_blocks
}

resource "aws_security_group_rule" "consul_cluster_traffic" {
  count             = var.create && var.use_consul ? 1 : 0
  security_group_id = aws_security_group.vault_server[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8501
  to_port           = 8501
  cidr_blocks       = var.cidr_blocks
}

resource "aws_security_group_rule" "consul_server_rpc_traffic" {
  count             = var.create && var.use_consul ? 1 : 0
  security_group_id = aws_security_group.vault_server[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8300
  to_port           = 8300
  cidr_blocks       = var.cidr_blocks
}

resource "aws_security_group_rule" "consul_lan_gossip_traffic" {
  count             = var.create && var.use_consul ? 1 : 0
  security_group_id = aws_security_group.vault_server[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = var.cidr_blocks
}

resource "aws_security_group_rule" "consul_dns_traffic" {
  count             = var.create && var.use_consul ? 1 : 0
  security_group_id = aws_security_group.vault_server[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8600
  to_port           = 8600
  cidr_blocks       = var.cidr_blocks
}
