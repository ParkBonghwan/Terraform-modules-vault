# AWS Vault Server Ports Terraform Module

- Vault Auto Unseal 을 수행하기 위한 KMS Key 를 생성합니다. 
 

## Environment Variables

- `AWS_DEFAULT_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Input Variables

- `create`: [Optional] 모듈 생성 여부입니다. 기본값은 "true"  
- `name`: [Optional] 리소스의 이름입니다. 기본값은 "vault-auto-unseal"
- `tags`: [Optional] 리소스에 설정할 태그 맵입니다. 기본값은 빈 맵 

 
## Outputs

- `vault_auto_unseal_key_arn`: Vault Auto Unseal 에서 사용할 KMS Key 의 ARN 입니다.

## Module Dependencies

_None_
 
 
