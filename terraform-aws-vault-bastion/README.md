# Vault Bastion Terraform Module

- 제공된 Public 서브넷에 Vault 에이전트가 설치된 Bastion 호스트를 생성합니다.
- 사용자가 개인 키를 제공하지 않는 경우 자동으로 AWS Keypair 를 생성합니다.

## Environment Variables

- `AWS_DEFAULT_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Input Variables

- `vpc_id`:  Bastion 호스트가 위치할 VPC ID 입니다.
- `subnet_id` : Bastion 호스트를 배포할 Public Subnet ID 를 입력합니다.
- `create`: [Optional] 모듈 생성, 기본값은 true입니다.
- `name`: [Optional] 리소스 이름에 사용할 Prefix (기본값은 "vault")입니다.
- `tags`: [Optional] 리소스에 설정할 태그의 맵으로, 기본값은 비어있습니다.
- `instance_type` :  [Optional] Bastion 호스트의 인스턴스 타입을 지정합니다.
- `ssh_key_name` :  [Optional] Bastion 호스트 인스턴스에 액세스하는 데 사용할 AWS 키 이름이며, 기본값은 SSH 키를 생성하는 것입니다. (ssh_key_override:false)
- `ssh_key_override` :  [Optional] 사용자가 가지고 있는 AWS Keypair 를 사용하는 경우 "true" 를 입력합니다(기본값은 false).
- `iam_instance_profile` :  [Optional] 인스턴스를 시작할 IAM 인스턴스 프로필입니다. 기본값은 null 입니다.

## Outputs

- `bastion_info.pubic_ip`: 생성한 Bastion 호스트의 Public IP 입니다.
- `bastion_info.security_group_id`: 생성한 Bastion 호스트의 Security Group ID 입니다.
- `private_key_info.key_name`:  생성된 AWS KeyPair 의 Key 이름입니다.
- `private_key_info.private_key_filename`: 생성된 AWS KeyPair 의 개인키 파일명입니다.
- `public_key_pem`: PEM 형식의 공개 키 데이터입니다.
- `private_key_info.public_key_openssh`: 생성한 개인 키의 OpenSSH authorized_keys 형식의 공개 키 데이터입니다.  

## Submodules

- github.com/ParkBonghwan/Terraform-modules-vault/terraform-aws-ssh-key-pair
- terraform-aws-modules/ec2-instance/aws