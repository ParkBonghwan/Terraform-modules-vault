# terraform-vault-secret-kv-forapp

- Application 환경별 Vault KV Secret Engine 을 만들기 위한 모듈

## Usage

```hcl
locals {
  sample_applications = [
    {
      name = "app1"
      envs = ["dev", "qa"]
    },
    {
      name = "app2"
      envs = ["aa", "bb", "cc"]
    }
  ]
}

resource "vault_auth_backend" "approle" {
  namespace = "nsqa"
  type      = "approle"
}

module "applications" {
  source         = "../modules/terraform-vault-secret-kv-forapp"
  create         = true
  enable_approle = true
  applications   = local.sample_applications
  namespace      = "nsqa"
  approle_path   = vault_auth_backend.approle.path
}

output "application" {
  value = module.applications
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
- `applications`: 온보딩할 애플리케이션 정보 입니다. name(string) , envs(list(string)) 정보를 기입합니다.
- `approle_path`: 애플리케이션이 로그인 토큰을 얻기 위한 approle 의 path 입니다. 
- `enable_approle`: 애플리케이션이 로그인 토큰을 얻기 위한 approle 을 생성할지 여부입니다.
- `namespace`: 애플리케이션이 속할 vault namespace 를 지정합니다.

## Outputs

- `result`: 생성된 resource 목록입니다. 