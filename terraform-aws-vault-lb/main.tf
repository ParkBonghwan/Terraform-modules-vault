# LB Security Group
resource "aws_security_group" "vault_lb" {
  count       = var.create ? 1 : 0
  name_prefix = "${var.name}-"
  description = "Security group for Vault ${var.name} LB"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "vault_lb_http_80" {
  count             = var.create ? 1 : 0
  security_group_id = aws_security_group.vault_lb[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = var.cidr_blocks
}

resource "aws_security_group_rule" "vault_lb_https_443" {
  count             = var.create && var.use_https ? 1 : 0
  security_group_id = aws_security_group.vault_lb[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = var.cidr_blocks
}

resource "aws_security_group_rule" "vault_lb_tcp_8200" {
  count             = var.create ? 1 : 0
  security_group_id = aws_security_group.vault_lb[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8200
  to_port           = 8200
  cidr_blocks       = var.cidr_blocks
}

resource "aws_security_group_rule" "outbound_tcp" {
  count             = var.create ? 1 : 0
  security_group_id = aws_security_group.vault_lb[count.index].id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
}

# LB
resource "random_id" "vault_lb" {
  count       = var.create ? 1 : 0
  byte_length = 4
  prefix      = "vault-lb-"
}

resource "aws_lb" "vault" {
  count    = var.create ? 1 : 0
  name     = random_id.vault_lb[count.index].hex
  internal = var.is_internal_lb ? true : false
  subnets  = var.subnet_ids
  #security_groups = var.use_secondary ? [aws_security_group.vault_lb[count.index].id, aws_security_group.vault_lb_secondary[count.index].id] : [aws_security_group.vault_lb[count.index].id]
  security_groups = compact(concat([aws_security_group.vault_lb[count.index].id],
    var.use_secondary ? [aws_security_group.vault_lb_secondary[count.index].id] : [],
    var.use_consul ? [aws_security_group.vault_lb_consul[count.index].id] : []
  ))

  tags = merge(var.tags, { "Name" = format("%s-vault-lb", var.name) })

  access_logs {
    bucket  = var.lb_bucket_override ? var.lb_bucket : aws_s3_bucket.vault_lb_access_logs[0].id
    prefix  = var.lb_bucket_prefix
    enabled = var.lb_logs_enabled
  }
}

resource "random_id" "vault_http_8200" {
  count       = var.create && !var.use_https ? 1 : 0
  byte_length = 4
  prefix      = "vault-http-8200-"
}

resource "aws_lb_target_group" "vault_http_8200" {
  count    = var.create && !var.use_https ? 1 : 0
  name     = random_id.vault_http_8200[count.index].hex
  vpc_id   = var.vpc_id
  port     = 8200
  protocol = "HTTP"
  tags     = merge(var.tags, { "Name" = format("%s-vault-http-8200", var.name) })

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = var.lb_health_check_path
    interval            = 30
  }
}

resource "aws_lb_listener" "vault_80" {
  count = var.create && !var.use_https ? 1 : 0

  load_balancer_arn = aws_lb.vault[count.index].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.vault_http_8200[count.index].arn
    type             = "forward"
  }
}

resource "aws_iam_server_certificate" "vault" {
  count             = var.create && var.use_https ? 1 : 0
  name              = random_id.vault_lb[count.index].hex
  certificate_body  = file(var.lb_cert)
  private_key       = file(var.lb_private_key)
  certificate_chain = file(var.lb_cert_chain)
  path              = "/${var.name}-${random_id.vault_lb[count.index].hex}/"
}

resource "random_id" "vault_https_8200" {
  count       = var.create && var.use_https ? 1 : 0
  byte_length = 4
  prefix      = "vault-https-8200-"
}

resource "aws_lb_target_group" "vault_https_8200" {
  count    = var.create && var.use_https ? 1 : 0
  name     = random_id.vault_https_8200[count.index].hex
  vpc_id   = var.vpc_id
  port     = 8200
  protocol = "HTTPS"
  tags     = merge(var.tags, { "Name" = format("%s-vault-https-8200", var.name) })

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    protocol            = "HTTPS"
    port                = "traffic-port"
    path                = var.lb_health_check_path
    interval            = 30
  }
}

resource "aws_lb_listener" "vault_443" {
  count = var.create && var.use_https ? 1 : 0

  load_balancer_arn = aws_lb.vault[count.index].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.lb_ssl_policy
  certificate_arn   = aws_iam_server_certificate.vault[count.index].arn

  default_action {
    target_group_arn = aws_lb_target_group.vault_https_8200[count.index].arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "vault_8200" {
  count = var.create ? 1 : 0

  load_balancer_arn = aws_lb.vault[count.index].arn
  port              = "8200"
  protocol          = var.use_https ? "HTTPS" : "HTTP"
  ssl_policy        = var.use_https ? var.lb_ssl_policy : ""
  certificate_arn   = var.use_https ? aws_iam_server_certificate.vault[0].arn : ""

  default_action {
    target_group_arn = var.use_https ? aws_lb_target_group.vault_https_8200[0].arn : aws_lb_target_group.vault_http_8200[0].arn
    type             = "forward"
  }
}

# ALB Log S3 Bucket
resource "random_id" "vault_lb_access_logs" {
  count       = var.create && !var.lb_bucket_override ? 1 : 0
  byte_length = 4
  prefix      = format("%s-vault-lb-access-logs-", var.name)
}

data "aws_elb_service_account" "vault_lb_access_logs" {
  count = var.create && !var.lb_bucket_override ? 1 : 0
}

resource "aws_s3_bucket" "vault_lb_access_logs" {
  count         = var.create && !var.lb_bucket_override ? 1 : 0
  bucket        = random_id.vault_lb_access_logs[count.index].hex
  tags          = merge(var.tags, { "Name" = format("%s-vault-lb-access-logs", var.name) })
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "vault_lb_access_logs" {
  count  = var.create && !var.lb_bucket_override ? 1 : 0
  bucket = aws_s3_bucket.vault_lb_access_logs[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "vault_lb_access_logs" {
  count = var.create && !var.lb_bucket_override ? 1 : 0
  statement {
    sid = "LBAccessLogs"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.vault_lb_access_logs[count.index].arn}/AWSLogs/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.vault_lb_access_logs[count.index].arn]
    }
  }
}

resource "aws_s3_bucket_policy" "vault_lb_access_logs" {
  count  = var.create && !var.lb_bucket_override ? 1 : 0
  bucket = aws_s3_bucket.vault_lb_access_logs[count.index].id
  policy = data.aws_iam_policy_document.vault_lb_access_logs[count.index].json
}

resource "aws_s3_bucket_public_access_block" "vault_lb_access_logs" {
  count  = var.create && !var.lb_bucket_override ? 1 : 0
  bucket = aws_s3_bucket.vault_lb_access_logs[count.index].id

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "vault_lb_access_logs" {
  count  = var.create && !var.lb_bucket_override ? 1 : 0
  bucket = aws_s3_bucket.vault_lb_access_logs[count.index].id

  rule {
    id = "logs"

    expiration {
      days = 90
    }

    filter {
      and {
        prefix = ""
      }
    }

    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

##----------------------------------------------------------------------------------------------
## Secondary
# LB Security Group (Secondary)
resource "aws_security_group" "vault_lb_secondary" {
  count       = var.create && var.use_secondary ? 1 : 0
  name_prefix = "${var.name}-secondary-"
  description = "Security group for Vault ${var.name} LB"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "vault_lb_http_8080_secondary" {
  count             = var.create && var.use_secondary ? 1 : 0
  security_group_id = aws_security_group.vault_lb_secondary[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_blocks       = var.cidr_blocks
}

resource "aws_security_group_rule" "vault_lb_https_8443_secondary" {
  count             = var.create && var.use_https && var.use_secondary ? 1 : 0
  security_group_id = aws_security_group.vault_lb_secondary[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8443
  to_port           = 8443
  cidr_blocks       = var.cidr_blocks
}


resource "aws_security_group_rule" "outbound_tcp_secondary" {
  count             = var.create && var.use_secondary ? 1 : 0
  security_group_id = aws_security_group.vault_lb_secondary[count.index].id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "vault_8443_secondary" {
  count = var.create && var.use_https && var.use_secondary ? 1 : 0

  load_balancer_arn = aws_lb.vault[count.index].arn
  port              = "8443"
  protocol          = "HTTPS"
  ssl_policy        = var.lb_ssl_policy
  certificate_arn   = aws_iam_server_certificate.vault[count.index].arn

  default_action {
    target_group_arn = aws_lb_target_group.vault_https_8200_secondary[count.index].arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "vault_8080_secondary" {
  count = var.create && !var.use_https && var.use_secondary ? 1 : 0

  load_balancer_arn = aws_lb.vault[count.index].arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.vault_http_8200_secondary[count.index].arn
    type             = "forward"
  }
}

resource "random_id" "vault_https_8200_secondary" {
  count       = var.create && var.use_https && var.use_secondary ? 1 : 0
  byte_length = 4
  prefix      = "vault-s-https-8200-"
}

resource "aws_lb_target_group" "vault_https_8200_secondary" {
  count    = var.create && var.use_https && var.use_secondary ? 1 : 0
  name     = random_id.vault_https_8200_secondary[count.index].hex
  vpc_id   = var.vpc_id
  port     = 8200
  protocol = "HTTPS"
  tags     = merge(var.tags, { "Name" = format("%s-vault-s-https-8200-", var.name) })

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    protocol            = "HTTPS"
    port                = "traffic-port"
    path                = var.lb_health_check_path
    interval            = 30
  }
}

resource "random_id" "vault_http_8200_secondary" {
  count       = var.create && !var.use_https && var.use_secondary ? 1 : 0
  byte_length = 4
  prefix      = "vault-s-http-8200-"
}


resource "aws_lb_target_group" "vault_http_8200_secondary" {
  count    = var.create && !var.use_https && var.use_secondary ? 1 : 0
  name     = random_id.vault_http_8200_secondary[count.index].hex
  vpc_id   = var.vpc_id
  port     = 8200
  protocol = "HTTP"
  tags     = merge(var.tags, { "Name" = format("%s-vault-s-http-8200-", var.name) })

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = var.lb_health_check_path
    interval            = 30
  }
}


##---------------------------------------------------------------------------------------
# Consul Backend 를 사용할 경우에 대한 고려 추가 

resource "random_id" "consul_http_8500" {
  count       = var.create && var.use_consul && !var.use_https ? 1 : 0
  byte_length = 4
  prefix      = "consul-http-8500-"
}

resource "random_id" "consul_https_8500" {
  count       = var.create && var.use_consul && var.use_https ? 1 : 0
  byte_length = 4
  prefix      = "consul-https-8500-"
}

resource "aws_security_group" "vault_lb_consul" {
  count       = var.create  && var.use_consul? 1 : 0
  name_prefix = "${var.name}-consul-"
  description = "Security group for Consul backend ${var.name} LB"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "consul_lb_tcp_8500" {
  count             = var.create && var.use_consul ? 1 : 0
  security_group_id = aws_security_group.vault_lb_consul[count.index].id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8500
  to_port           = 8500
  cidr_blocks       = var.cidr_blocks
}

resource "aws_security_group_rule" "outbound_consul_lb_tcp_8500" {
  count             = var.create && var.use_consul ? 1 : 0
  security_group_id = aws_security_group.vault_lb_consul[count.index].id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb_target_group" "consul_http_8500" {
  count    = var.create && var.use_consul && !var.use_https ? 1 : 0
  name     = random_id.consul_http_8500[count.index].hex
  vpc_id   = var.vpc_id
  port     = 8500
  protocol = "HTTP"
  tags     = merge(var.tags, { "Name" = format("%s-consul-http-8500", var.name) })

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = "/v1/health/node/my-node"
    interval            = 30
  }
}

resource "aws_lb_target_group" "consul_https_8500" {
  count    = var.create && var.use_consul && var.use_https ? 1 : 0
  name     = random_id.consul_https_8500[count.index].hex
  vpc_id   = var.vpc_id
  port     = 8500
  protocol = "HTTPS"
  tags     = merge(var.tags, { "Name" = format("%s-consul-https-8500", var.name) })

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    protocol            = "HTTPS"
    port                = "traffic-port"
    path                = "/v1/health/node/my-node"
    interval            = 30
  }
}

resource "aws_lb_listener" "consul_8500" {
  count = var.create && var.use_consul ? 1 : 0

  load_balancer_arn = aws_lb.vault[count.index].arn
  port              = "8500"
  protocol          = var.use_https ? "HTTPS" : "HTTP"
  ssl_policy        = var.use_https ? var.lb_ssl_policy : ""
  certificate_arn   = var.use_https ? aws_iam_server_certificate.vault[0].arn : ""

  default_action {
    target_group_arn = var.use_https ? aws_lb_target_group.consul_https_8500[0].arn : aws_lb_target_group.consul_http_8500[0].arn
    type             = "forward"
  }
}
