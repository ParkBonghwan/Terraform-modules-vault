
output "vault_instances_private_ips" {
  value = aws_instance.vault.*.private_ip
}

output "vault_user_data" {
  value = data.template_file.userdata.rendered
}

output "vault_instances_asg_private_ips" {
  value = data.aws_instances.vault.*.private_ips
}

/*
output "vault_user_data" {
  value = local.vault_user_data
}

output "vault_asg_name" {
  value = aws_autoscaling_group.vault.*.name
}


*/