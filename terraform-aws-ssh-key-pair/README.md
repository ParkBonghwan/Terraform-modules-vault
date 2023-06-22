# AWS SSH Keypair Terraform Module

- RSA 개인 키를 생성합니다.
- 개인 키를 PEM으로 인코딩합니다.
- 로컬로 개인 키를 다운로드하고 로컬 키 파일 권한을 0600으로 업데이트합니다. (윈도우는 권한 설정하지 않음)
- AWS SSH 키쌍을 생성합니다.

## Environment Variables

- `AWS_DEFAULT_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Input Variables

- `create`: [Optional] 모듈 생성, 기본값은 true입니다.
- `name`: [Optional] 생성될 AWS 키쌍의 이름(기본값은 임의의 바이트가 추가된 "ssh-keypair-aws")입니다.
- `rsa_bits`: [Optional] 생성된 RSA 키의 비트 단위 크기입니다. 기본값은 "2048"입니다.

## Outputs
 
- `private_key_info.private_key_filename`: 파일 확장명이 있는 개인 키 파일 이름입니다. 
- `private_key_info.public_key_openssh`: 선택한 개인 키 형식이 호환되는 경우 OpenSSH authorized_keys 형식의 공개 키 데이터입니다. 모든 RSA 키가 지원되며, 커브가 "P256", "P384" 및 "P251"인 ECDSA 키가 지원됩니다. 호환되지 않는 ECDSA 커브를 선택한 경우 이 속성은 비어 있습니다.
- `name`:  AWS keypair 의 이름입니다.


## Submodules

- [TLS Private Key Terraform Module](https://github.com/ParkBonghwan/Terraform-modules-vault/terraform-tls-private-key)
- `안쓰는 중`
  
