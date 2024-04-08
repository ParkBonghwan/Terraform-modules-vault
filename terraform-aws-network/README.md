# AWS Network Terraform Module

AWS에 다음을 포함하는 표준 네트워크를 생성합니다:

- 하나의 VPC
- 3개의 공용 서브넷
- 3개의 프라이빗 서브넷
- 각 퍼블릭 서브넷에 NAT 게이트웨이 1개 

## Environment Variables

- `AWS_DEFAULT_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Input Variables

- `create`: [Optional] 모듈 생성, 기본값은 true입니다.
- `name`: [Optional] 리소스 이름 Prefix, 기본값은 "vault-aws-network"입니다.
- `create_vpc`: [Optional] VPC를 생성할지 또는 VPC ID를 전달할지 여부를 결정합니다.
- `vpc_id`: [Optional] 재정의할 VPC ID로, "create_vpc"가 거짓인 경우 입력합니다.
- `vpc_cidr`: [Optional] VPC CIDR 블록입니다. 기본값은 10.139.0.0/16 입니다.
- `vpc_cidrs_public`: [Optional] Public 서브넷을 위한 VPC CIDR 블록, 기본값은 "10.139.1.0/24", "10.139.2.0/24", "10.139.3.0/24"  
- `nat_count`: [Optional] 공용 서브넷에서 프로비저닝할 NAT 게이트웨이 수, 기본값은 Public 서브넷 수입니다.
- `vpc_cidrs_private`: [Optional] Private 서브넷을 위한 VPC CIDR 블록, 기본값은 "10.139.11.0/24", "10.139.12.0/24", "10.139.13.0/24".
- `tags`: [Optional] 리소스에 설정할 태그의 맵으로, 기본값은 비어있습니다.

## Outputs
 
- `vpc_cidr`: VPC CIDR 블록 
- `vpc_id`:  VPC ID 
- `subnet_public_ids`: Public 서브넷 IDs.
- `subnet_private_ids`: Private 서브넷 IDs. 
 
## Submodules

이 모듈에는 하위 모듈이 없습니다.
 
