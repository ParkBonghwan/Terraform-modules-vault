# AWS Vault Load Balancer Terraform Module

- AWS 에서 Vault 애플리케이션 로드 밸런서를 프로비저닝합니다. 
- AWS S3 에  Vault 애플리케이션 로드 밸런서에 대한 로그 버킷을 프로비저닝 합니다.
- AWS ACM 에 Vault 애플리케이션 로드 밸런서에 대한 인증서를 등록합니다.
- AWS Route53 에 Vault 도메인을 A 레코드로 등록합니다.

### Environment Variables

- `AWS_DEFAULT_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Input Variables

- `create`: [Optional] 모듈 생성, 기본값은 true입니다.
- `name`: [Optional] 리소스의 이름 Prfix, 기본값은 "vault-lb-aws"입니다.
- `vpc_id`: [Required] LB를 프로비저닝할 VPC ID입니다.
- `cidr_blocks`: [Optional] LB 접근을 제한하기 위해 Security Group 에 설정할 CIDR 블록입니다.
- `subnet_ids`: [Optional] LB를 프로비저닝할 서브넷 ID입니다.
- `is_internal_lb`: [Optional] 내부 로드 밸런서이를 사용할지 여부이며 기본값은 true입니다.
- `use_https`: [Optional]  LB 사용시 https 통신을 할지 여부입니다. 기본값은 false 입니다.
- `use_secondary`: [Optional] Vault 를 DR 로 구성하는 경우 사용합니다. 여기에서는 단순 테스트용이며 실제로는 다른 Region 에 DR 이 배포되어 있어야 합니다.
- `lb_cert`: [Optional] LB 인증서(certificate.crt) 파일 경로입니다. 
- `lb_private_key`: [Optional]  LB 인증서의 개인키(private.key)파일 경로입니다.
- `lb_cert_chain`: [Optional]  LB 인증서 체인 (ca_bundle.crt) 파일의 경로입니다.
- `lb_ssl_policy`: [Optional] LB에 대한 SSL 정책, 기본값은 "ELBSecurityPolicy-TLS-1-2-2017-01"입니다.
- `lb_bucket`: [Optional] LB 액세스 로그에 대한 S3 버킷 재정의, 재정의하는 경우 `lb_bucket_override`를 true로 설정합니다.
- `lb_bucket_override`: [Optional] 액세스 로그를 위해 생성된 기본 S3 버킷을 재정의하고, 기본값은 false 입니다.
- `lb_bucket_prefix`: [Optional]  LB 액세스 로그의 S3 버킷 Prefix 입니다.
- `lb_logs_enabled`: [Optional] S3 버킷 LB 액세스 로그 사용, 기본값은 true입니다.
- `lb_health_check_path`: [Optional] Vault의 상태를 확인할 수 있는 엔드포인트입니다.
- `create_domain`: [Optional] Route53 에 A 레코드 생성, 기본값은 true입니다.
- `domain_name`: [Optional] 도메인 이름 
- `route53_zone_name`: [Optional] Route53 Zone 이름
- `use_consul`: [Optional] Consul Backend 를 사용할 시 `true` 를 체크하면 Consul 을 위한 Listner, SG, TargetGroup 을 추가합니다. 기본값은 `false`
- `tags`: [Optional] 리소스에 설정할 태그 맵, 기본값은 비어 있습니다.

## Outputs

- `vault_lb_sg_id`: Vault LB 의 Security Group ID 입니다.
- `vault_tg_http_8200_arn`: Vault LB 의 HTTP 8200 타겟 그룹의 arn 입니다.
- `vault_tg_https_8200_arn`:  Vault LB 의 HTTPS 8200 타겟 그룹의 arn 입니다.
- `vault_lb_dns`: 볼트 로드 밸런서 DNS 이름입니다.

## Module Dependencies

해당 모듈은 독립 모듈로 내부에 다른 모듈을 사용하지 않습니다.
