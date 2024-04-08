data "aws_availability_zones" "main" {}

data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-*-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "random_id" "name" {
  count = var.create ? 1 : 0

  byte_length = 4
  prefix      = "${var.name}-"
}


resource "aws_security_group" "bastion" {
  count = var.create ? 1 : 0

  name_prefix = "${var.name}-bastion-"
  description = "Security Group for ${var.name} Bastion hosts"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { "Name" = format("%s-bastion", var.name) })
}

resource "aws_security_group_rule" "ssh" {
  count = var.create ? 1 : 0

  security_group_id = aws_security_group.bastion[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_public" {
  count = var.create ? 1 : 0

  security_group_id = aws_security_group.bastion[count.index].id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

locals {
  bastion_name = format("bastion-%s", random_id.name[0].hex)
  user_data = templatefile("${path.module}/templates/userdata.sh.tpl", {})
}

module "ssh_keypair_aws" {
  count  = var.create && !var.ssh_key_override ? 1 : 0
  source = "github.com/ParkBonghwan/Terraform-modules-vault/terraform-aws-ssh-key-pair"
  name   = var.name
}

module "bastion_ec2_instance" {
  count   = var.create ? 1 : 0
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = " ~> 3.6.0"

  name = local.bastion_name

  ami                  = data.aws_ami.amazon_linux2.id
  instance_type        = var.instance_type
  key_name             = var.ssh_key_override ? var.ssh_key_name : module.ssh_keypair_aws[0].name
  iam_instance_profile = var.iam_instance_profile

  vpc_security_group_ids = aws_security_group.bastion.*.id
  subnet_id              = var.subnet_id
  user_data_base64       = base64encode(local.user_data)

  tags = var.tags
}
