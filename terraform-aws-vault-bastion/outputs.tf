output "bastion_info" {
  value = {
    pubic_ip = var.create ?  module.bastion_ec2_instance[0].public_ip : null
    security_group_id =  var.create ? aws_security_group.bastion[0].id : null
  } 
}

output "private_key_info" {
  value = {
    key_name = var.create ? (var.ssh_key_override ? var.ssh_key_name : module.ssh_keypair_aws[0].name) : null
  }
}