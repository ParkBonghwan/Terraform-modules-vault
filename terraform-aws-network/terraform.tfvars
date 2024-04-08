create            = true
create_vpc        = true
vpc_cidr          = "172.19.0.0/16"
vpc_cidrs_public  = ["172.19.0.0/20", "172.19.16.0/20", "172.19.32.0/20", ]
nat_count         = "1"
vpc_cidrs_private = ["172.19.48.0/20", "172.19.64.0/20", "172.19.80.0/20", ]
tags              = { "author" = "bong" }
