output "vault_lb_sg_id" {
  value = var.create? aws_security_group.vault_lb[0].id : null
}

output "vault_tg_http_8200_arn" {
  value = var.create && !var.use_https ?  aws_lb_target_group.vault_http_8200[0].arn : null
}

output "vault_tg_https_8200_arn" {
  value = var.create && var.use_https ? aws_lb_target_group.vault_https_8200[0].arn : null
}

output "vault_lb_dns" {
  value = var.create ? aws_lb.vault[0].dns_name : null
}

output "vault_lb_zone_id" {
  value = var.create ? aws_lb.vault[0].zone_id : null
}


output "vault_lb_arn" {
  value =  var.create ? aws_lb.vault[0].arn : null
}

# Secondary
output "vault_tg_http_8200_arn_secondary" {
  value = var.create && !var.use_https && var.use_secondary ?  aws_lb_target_group.vault_http_8200_secondary[0].arn : null
}

output "vault_tg_https_8200_arn_arn_secondary" {
  value = var.create && var.use_https && var.use_secondary ? aws_lb_target_group.vault_https_8200_secondary[0].arn : null
}

# Consul
output "vault_tg_http_8500_arn" {
  value = var.create && !var.use_https && var.use_consul ?  aws_lb_target_group.consul_http_8500[0].arn : null
}

output "vault_tg_https_8500_arn" {
  value = var.create && var.use_https && var.use_consul ? aws_lb_target_group.consul_https_8500[0].arn : null
}
