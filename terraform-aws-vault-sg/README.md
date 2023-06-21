# AWS Vault Server Ports Terraform Module

- AWS에 표준 Vault 서버 보안 그룹을 생성합니다.
 

## Environment Variables

- `AWS_DEFAULT_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Input Variables

- `create`: [Optional] 모듈 생성 여부입니다. 기본값은 "true"  
- `name`: [Optional] 리소스의 이름입니다. 기본값은 "vault-server" 
- `vpc_id`: [Required] 리소스를 프로비저닝할 VPC ID입니다.
- `cidr_blocks`: [Required] 보안 그룹의 CIDR 블록입니다. 
- `lb_sg_id`: [Optional] LB 보안 그룹의 ID 입니다. 
- `bastion_sg_id`: [Optional] Bastion 호스트 보안 그룹의 ID 입니다. 
- `use_consul`: [Optional] Consul 을 Vault Backend 로 사용할지 여부입니다. 기본값은 false 입니다.
- `tags`: [Optional] 리소스에 설정할 태그 맵입니다. 기본값은 빈 맵 

## Outputs

- `vault_server_sg_id`: Vault 서버 Security Group ID 입니다.

## Module Dependencies

_None_