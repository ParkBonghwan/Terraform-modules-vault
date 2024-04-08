# AWS Vault Server Ports Terraform Module

- AWS에 표준 Vault 서버 보안 그룹을 생성합니다.
 

## Environment Variables

- `AWS_DEFAULT_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Input Variables

- `create`: [Optional] 모듈 생성 여부입니다. 기본값은 "true"
- `name`: [Optional] 리소스의 이름입니다. 기본값은 "vault-profile" 
- `auto_unseal_kms_key_arn`: [Optional] Vault Auto Unseal 을 위한 KMS 키의 ARN
- `snapshot_bucket_arn`: [Optional] Vault 스냅샷을 저장하기 위한 S3 버킷의 ARN
- `audit_log_group_arn`: [Optional] Vault Audit 로그를 저장하기 위한 로그 그룹의 ARN
- `secretsmanager_secret_arn`: [Optional] 볼트 초기화 결과 저장을 위한 시크릿 매니저의 ARN
- `iam_permissions_boundary`: [Optional] IAM Role 에 대한 Permission Boundary 정책

## Outputs

- `vault_instance_role_name`: Vault 서버 인스턴스에 적용할 Instance Role 입니다.

## Module Dependencies

_None_
 
 
