# terraform-vault-namespace

- Vault namesapce 를 만들기 위한 모듈

## Usage

```hcl
module "vault_namespace" {
  source      = "../modules/terraform-vault-namespace"
  create      = true
  name        = "ns-dept" # {조직}_{서비스}{용도} > team1, Frontend, Development
}

output "vault_namespace" {
  value = {
    admin_token = module.vault_namespace.vault-admin-token
    name        = module.vault_namespace.vault-namespace-path
  }
  sensitive = true
}

```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 0.15 |

## Providers

| Name  | Version |
| ----- | ------- |
| vault | >= 3.13 |


## Input Variables

- `create`: 모듈 생성 여부, 기본값은 `true`
- `name`: 생성할 Vault 네임스페이스의 이름입니다.

## Outputs

- `vault-namespace-path`: 생성된 네임스페이스의 전체 경로
- `vault-admin-token`: 네임스페이스 관리를 위해 생성된 Vault 토큰