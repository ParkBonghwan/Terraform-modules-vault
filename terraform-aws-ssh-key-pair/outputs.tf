
output "private_key_info" {
  value = {
    private_key_filename = "${module.tls_private_key.private_key_filename}"
    public_key_openssh   = "${module.tls_private_key.public_key_openssh}"
  }
}

output "name" {
  value = element(concat(aws_key_pair.main.*.key_name, tolist([])), 0)
}
