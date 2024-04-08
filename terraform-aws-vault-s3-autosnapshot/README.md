# AWS Vault Server Ports Terraform Module

- AWS 에 Vault Snapshot 을 저장하기 위한 S3 저장소를 생성합니다.
 

## Environment Variables

- `AWS_DEFAULT_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Input Variables

- `create`: [Optional] 모듈 생성 여부입니다. 기본값은 "true"  
- `name`: [Optional] 리소스의 이름입니다. 기본값은 "vault-snapshot"
- `tags`: [Optional] 리소스에 설정할 태그 맵입니다. 기본값은 빈 맵 


 
## Outputs

- `vault_s3_snapshot_arn`: Vault 서버의 Snapshot 을 저장하기 위한 S3 저장소의 arn

## Module Dependencies

_None_
 
 
