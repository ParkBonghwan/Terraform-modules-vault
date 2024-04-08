# Vault SSH Key 복사를 위한 Terraform 구성

이 Terraform 구성은 SSH 개인 키를 원격 서버로 복사하기 위한 Terraform 코드입니다.

## 사전 요구사항

이 구성을 사용하기 전에 다음 사항들을 확인해주세요:

- 유효한 SSH 개인 키 파일이 로컬에 존재해야 합니다.
- Vault 배스천 서버의 공용 IP 주소가 필요합니다.
- 서버에 개인 키를 복사할 원격 경로가 지정되어야 합니다.
- SSH 연결에 사용할 사용자명이 필요합니다.

## Input Variables

| 변수명                    | 설명                                           | 타입   | 기본값         |
| ------------------------ | ---------------------------------------------- | ------ | ------------- |
| create                   | 모듈 생성 여부                                  | bool   |  true         |
| server_ip                | Vault 배스천 서버의 공용 IP 주소                 | string |               |
| private_key_local_path   | 로컬에서의 개인 키 파일 경로                     | string |               |
| private_file_local_path   | 로컬에서 리모트로 복사할 파일 경로               | string |               |
| private_file_remote_path  | 로컬 파일을 저장할 원격 경로                     | string |               |
| permission                | 원격 저장시 파일의 Permission                   | string | 400           |
| server_user              | SSH 연결에 사용할 사용자명                       | string |               |

## Outputs

이 Terraform 구성은 어떠한 출력 변수도 제공하지 않습니다.

## Cautions

- SSH 개인 키 파일은 안전하게 저장되어야 하며, 버전 관리에 포함되거나 공개적으로 공유되지 않아야 합니다.
- 원격 서버에 필요한 SSH 액세스 및 권한이 올바르게 구성되어 있는지 확인해주세요.

질문이나 문제가 있으시면 GitHub 저장소의 이슈 페이지에 문의해주세요.