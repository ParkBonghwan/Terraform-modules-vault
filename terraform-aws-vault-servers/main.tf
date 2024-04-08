data "aws_region" "current" {}

resource "random_id" "vault" {
  byte_length = 4
  prefix      = "${var.name}-"
}


locals {
  server_name = var.vault_server_name != "" ? var.vault_server_name : random_id.vault.hex
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

data "aws_ami" "centos-linux-8" {
  most_recent = true
  owners      = ["679593333241"]
  filter {
    name   = "name"
    values = ["CentOS*8*x86_64*"]
  }
}

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

##-----------------------------------------------------------------------------------------------
##  Vault 설치 Userdata
##-----------------------------------------------------------------------------------------------
data "template_file" "userdata" {
  template = file("${path.module}/templates/install_by_${var.install_method}.sh.tpl")
  vars = {
    license                   = var.license_file != null ? file(var.license_file) : ""
    region                    = data.aws_region.current.name
    tagname                   = "Name"
    tagvalue                  = local.server_name
    domain                    = var.domain_name
    version                   = var.vault_version
    kms_key_arn               = var.auto_unseal_arn != null ? var.auto_unseal_arn : ""
    certificate_body          = var.lb_use_https ? (var.certificate_body != null ? file(var.certificate_body) : "") : ""
    private_key               = var.lb_use_https ? (var.private_key != null ? file(var.private_key) : "") : ""
    certificate_chain         = var.lb_use_https ? (var.certificate_chain != null ? file(var.certificate_chain) : "") : ""
    autopilot_upgrade_version = var.use_autopilot_upgrade ? var.vault_version : ""
    use_telemetry             = var.use_telemetry ? "true" : ""
  }
}

##-----------------------------------------------------------------------------------------------
## Auto Scaling Group 을 통한 Vault 설치
##-----------------------------------------------------------------------------------------------
resource "aws_launch_template" "vault" {
  count         = var.create && var.use_auto_scaling ? 1 : 0
  name          = format("%s-launch-template", local.server_name)
  image_id      = var.image_id != null ? var.image_id : data.aws_ami.amazon_linux2.id
  instance_type = var.inst_type
  key_name      = var.ssh_key_pair_name
  user_data     = base64encode(data.template_file.userdata.rendered)
  vpc_security_group_ids = [
    var.server_security_group_id
  ]

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = "gp3"
      volume_size           = 100
      throughput            = 150
      iops                  = 3000
      delete_on_termination = true
    }
  }

  iam_instance_profile {
    name = var.instance_profile_name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_autoscaling_group" "vault" {
  count               = var.create && var.use_auto_scaling ? 1 : 0
  name                = local.server_name
  min_size            = var.inst_size != 0 ? var.inst_size : length(var.subnet_ids)
  max_size            = var.inst_size != 0 ? var.inst_size : length(var.subnet_ids)
  desired_capacity    = var.inst_size != 0 ? var.inst_size : length(var.subnet_ids)
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.lb_target_group_arns
  force_delete        = true

  launch_template {
    id      = aws_launch_template.vault[count.index].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = local.server_name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }
}

data "aws_instances" "vault" {
  count = var.create && var.use_auto_scaling ? 1 : 0
  filter {
    name   = "tag:Name"
    values = [format("%s", local.server_name)]
  }
  instance_state_names = ["running", "pending"]
  depends_on           = [aws_autoscaling_group.vault]
}

##-----------------------------------------------------------------------------------------------
## VM 을 통한 Vault 설치
##-----------------------------------------------------------------------------------------------
resource "aws_instance" "vault" {
  count         = var.create && !var.use_auto_scaling ? (var.inst_size != 0 ? var.inst_size : length(var.subnet_ids)) : 0
  ami           = var.image_id != null ? var.image_id : data.aws_ami.amazon_linux2.id
  instance_type = var.inst_type
  key_name      = var.ssh_key_pair_name

  subnet_id            = length(var.subnet_ids) > 0 ? var.subnet_ids[count.index % length(var.subnet_ids)] : null
  iam_instance_profile = var.instance_profile_name

  root_block_device {
    delete_on_termination = true
    volume_size           = 100
    volume_type           = "gp2"
  }

  vpc_security_group_ids = [
    var.server_security_group_id
  ]

  user_data_base64            = base64encode(data.template_file.userdata.rendered)
  user_data_replace_on_change = true

  tags = merge(var.tags, { "Name" = local.server_name })
}

resource "aws_lb_target_group_attachment" "vault" {
  count            = var.create && !var.use_auto_scaling ? (var.inst_size != 0 ? var.inst_size : length(var.subnet_ids)) : 0
  target_group_arn = var.lb_target_group_arns[0]
  target_id        = aws_instance.vault[count.index].id
  port             = 8200
}
