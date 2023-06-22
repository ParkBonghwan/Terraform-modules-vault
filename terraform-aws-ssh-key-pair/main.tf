module "tls_private_key" {
  source   = "github.com/ParkBonghwan/Terraform-modules-vault/terraform-tls-private-key"
  create   = var.create
  name     = var.name
  rsa_bits = var.rsa_bits
}

resource "aws_key_pair" "main" {
  count = var.create ? 1 : 0

  key_name_prefix = "${module.tls_private_key.private_key_name}-"
  public_key      = module.tls_private_key.public_key_openssh
}
