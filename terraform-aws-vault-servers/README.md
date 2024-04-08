# AWS Vault Server Terraform Module

- AWS에 Vault 서버를 프로비저닝 하기 위한 모듈입니다.
 

## Environment Variables

- `AWS_DEFAULT_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Input Variables

- `create`: [Optional] 모듈 생성 여부입니다. 기본값은 \"true\" 
- `name`: [Optional] 리소스의 이름입니다. 기본값은 \"vault-server\"
- `auto_unseal_arn`: [Optional] Vault Auto Unseal 을 위한 AWS KMS 키의 ARN
- `vault_secrets_arn`: [Optional] Vault 용 AWS 시크릿 매니저 시크릿의 ARN,  기본값은 \"null\"
- `domain_name`: [Optional] Vault 도메인 이름
- `vault_enterprise_deploy`: [Optional] Vault Enterprise 를 배포할지 여부입니다. 기본값은 \"false\"
- `certificate_body`: [Optional] LB IAM 서버 인증서의 파일 경로입니다. 기본값은 \"null\"
- `private_key`: [Optional] LB IAM 서버 인증서를 위한 개인 키 파일 경로입니다. 기본값은 \"null\"
- `certificate_chain`: [Optional] LB IAM 서버 인증서를 위한 인증서 체인 파일 경로입니다. 기본값은 \"null\"
- `inst_type`: [Optional] Vault 서버 생성을 위한 인스턴스 타입입니다. 기본값은 \"m5.xlarge\"
- `ssh_key_pair_name`: [Optional] Vault 인스턴스에 대한 SSH 액세스를 위한 SSH Keypair 이름 입니다.
- `server_security_group_id`: [Optional] Vault 인스턴스에 적용할 Security Group 의 ID 입니다.
- `instance_profile_name`: [Optional] Vault 인스턴스 프로필의 이름입니다.
- `subnet_ids`: [Optional] VM 이 배포될 서브넷입니다. 
- `lb_target_group_arns`: [Optional] LB 대상 그룹의 ARN 입니다.
- `license_file`: [Optional] Vault License 파일의 경로입니다.
- `inst_size`: [Optional] Vault 클러스터를 구성할 인스턴스 수, 사용하지 않는 경우 subnet 의 count 가 사용됩니다. 기본값은 \"0\"
- `use_auto_scaling`: [Optional] Auto Scaing Group 을 사용할지 여부, 기본값은 \"true\" 이며 \"false\" 인 경우 일반 Instance 를 부트스트래핑 합니다.
- `image_id`: [Optional] Vault 인스턴스를 시작할 AMI, 재정의하지 않는 경우 AmazonLinux 이미지가 사용됩니다.
- `install_method`: [Optional] Vault 설치시 Pakcage Manager 를 사용할지, Binary 특정 버전을 사용할지 , Airgap 설치인지 지정, 디폴트는 Pakcage Manager 사용
- `lb_use_https`: [Optional] Vault Cluster 를 구성하는 LB 가 Vault 와 통신할 때 HTTPS 를 사용하는지 여부
- `vault_version`: [Optional] Binary 를 사용하여 Vault 를 설치하는 경우 사용할 Vault 버전, 기본값은 \"1.2.1\"
- `use_autopilot_upgrade`: [Optional] Vault Auto upgrade 를 사용할지 여부
- `vault_server_name`: [Optional] Vault 클러스터를 구성할 인스턴스명, 값이 없으면 리소스명+Postfix 형태의 랜덤 서버명이 부여됩니다.
- `use_telemetry`: [Optional] Vault 클러스터에서 Telemetry Metric 을 생성할지 여부
- `tags`: [Optional] 리소스에 설정할 태그 맵입니다. 기본값은 빈 맵
 
## Outputs

- `vault_user_data`: Vault 서버 구성시 사용되는 UserData 정보 입니다.
- `vault_instances_private_ips`: Vault ASG 에 구성된 인스턴스의 Private IPs 입니다.
- `vault_launch_template_id`: Vault ASG 에 구성된 인스턴스의 Private IPs 입니다.
- `vault_asg_name`: Vault ASG 의 이름입니다.

## Module Dependencies

_None_