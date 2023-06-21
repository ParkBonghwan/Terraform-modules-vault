resource "random_id" "vault" {
  count       = var.create ? 1 : 0
  byte_length = 4
  prefix      = "${var.name}-"
}

locals {
  instance_profile_policies = [
    # Cloud auto join
    {
      create = true
      effect = "Allow"
      actions = [
        "ec2:DescribeInstances",
      ]
      resources = ["*"]
    },
    # Auto Unseal
    {
      create = var.create && var.auto_unseal_kms_key_arn != null ? true : false
      effect = "Allow"
      actions = [
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:Decrypt",
      ]
      resources = [var.auto_unseal_kms_key_arn]
    },
    # Intergrated Storage Backup
    {
      create = var.create && var.snapshot_bucket_arn != null ? true : false
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:DeleteObject"
      ]
      resources = [var.create && var.snapshot_bucket_arn != null ? "${var.snapshot_bucket_arn}/*.snap" : null]
    },
    {
      create = var.create && var.snapshot_bucket_arn != null ? true : false
      effect = "Allow"
      actions = [
        "s3:ListBucket",
        "s3:GetObject"
      ]
      resources = [var.create && var.snapshot_bucket_arn != null ? "${var.snapshot_bucket_arn}/*" : null]
    },
    # Vault Token Store
    {
      create = var.create && var.secretsmanager_secret_arn != null ? true : false
      effect = "Allow"
      actions = [
        "secretsmanager:Create*",
        "secretsmanager:Put*",
        "secretsmanager:Update*",
      ]
      resources = [var.secretsmanager_secret_arn]
    },    
    # Cloud watch log group & log stream
    {
      create = var.create && var.audit_log_group_arn != null ? true : false
      effect = "Allow"
      actions = [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics"
      ]
      resources = ["*"]
    },
    {
      create = var.create && var.audit_log_group_arn != null ? true : false
      effect = "Allow"
      actions = [
        "ssm:GetParameter"
      ]
      resources = ["arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"]
    },
    {
      create = var.create && var.audit_log_group_arn != null ? true : false
      effect = "Allow"
      actions = [
        "ec2:DescribeVolumes",
        "ec2:DescribeTags",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:CreateLogGroup"
      ]
      resources = ["*"]
    },
  ]
}

resource "aws_iam_instance_profile" "vault" {
  count       = var.create ? 1 : 0
  name_prefix = random_id.vault[count.index].hex
  role        = aws_iam_role.instance_role[count.index].name
}


data "aws_iam_policy_document" "instance_role" {
  count = var.create ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance_role" {
  count                = var.create ? 1 : 0
  name                 = "${random_id.vault[count.index].hex}-instance-role"
  permissions_boundary = var.iam_permissions_boundary
  assume_role_policy   = data.aws_iam_policy_document.instance_role[count.index].json
}

data "aws_iam_policy_document" "vault_policies" {
  dynamic "statement" {
    for_each = [for p in local.instance_profile_policies : p if p.create]
    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_role_policy" "vault_policies" {
  count                = var.create ? 1 : 0  
  name   =  "${random_id.vault[count.index].hex}-instance-policy"
  role   = aws_iam_role.instance_role[count.index].id
  policy = data.aws_iam_policy_document.vault_policies.json
}
