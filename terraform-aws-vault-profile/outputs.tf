output "instance_role_name" {
  value = var.create ? aws_iam_instance_profile.vault[0].name : null
}