

create            = true
create_domain     = true
name              = "vault-lb-aws"
vpc_id            = "vpc-028e268348f980c08"
cidr_blocks       = ["0.0.0.0/0"] # ["172.19.0.0/16"]
subnet_ids        = ["subnet-0b93268e3af90c2ea", "subnet-0d519beb507ddb45a", "subnet-03bf4d230f246d47a", ]
is_internal_lb    = false
use_https         = true
lb_cert           = "D:/keys/vault.idtplateer.com/certificate.crt"
lb_private_key    = "D:/keys/vault.idtplateer.com/private.key"
lb_cert_chain     = "D:/keys/vault.idtplateer.com/ca_bundle.crt"
lb_logs_enabled   = true
tags              = { "author" = "bong" }
