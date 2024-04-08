#!/usr/bin/env bash

# Reference Site : https://github.com/hashicorp/learn-vault-raft/tree/main/raft-storage/aws/templates

imds_token=$( curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 30" -XPUT 169.254.169.254/latest/api/token )
instance_id=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/instance-id )
local_ipv4=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/local-ipv4 )

sudo timedatectl set-timezone UTC

##--------------------------------------------------------------------
## TLS Certificate 와 License 파일 저장 > 실제 이 작업은 Image 구울때 들어가야 함, 여기에서는 편의를 위해 제공

sudo mkdir -p /opt/vault/
sudo mkdir -p /opt/vault/tls
sudo mkdir -p /opt/vault/data
sudo mkdir -p /opt/vault/logs
sudo mkdir -pm 0755 /etc/vault.d

%{ if certificate_body != "" &&  private_key != "" && certificate_chain != "" }
echo "${certificate_body}" | sudo tee /opt/vault/tls/vault-cert.pem > /dev/null
echo "${private_key}" | sudo tee /opt/vault/tls/vault-key.pem  > /dev/null
echo "${certificate_chain}" | sudo tee /opt/vault/tls/vault-ca.pem > /dev/null
%{ endif }

%{ if license != "" }
echo "${license}" | sudo tee /opt/vault/vault.hclic > /dev/null
%{ endif }

##--------------------------------------------------------------------
## Vault 사용자 추가

add_vault_user() {
  USER_NAME="vault"
	USER_COMMENT="HashiCorp Vault user"
	USER_GROUP="vault"
	USER_HOME="/srv/vault"
	
    DIST=$(cat /etc/os-release | grep '^ID=')
    
    case $DIST in
    'ID=ubuntu' | 'ID=debian')
        if ! getent group $USER_GROUP >/dev/null
        then
          sudo addgroup --system $USER_GROUP >/dev/null
        fi
        
        if ! getent passwd $USER_NAME >/dev/null
        then
          sudo adduser \
            --system \
            --disabled-login \
            --ingroup "$USER_GROUP" \
            --home "$USER_HOME" \
            --no-create-home \
            --gecos "$USER_COMMENT" \
            --shell /bin/false \
            $USER_NAME  >/dev/null
        fi
        ;;
    'ID="centos"' | 'ID="rhel"' | 'ID="amzn"')
        sudo /usr/sbin/groupadd --force --system $USER_GROUP
        if ! getent passwd $USER_NAME >/dev/null ; then
          sudo /usr/sbin/adduser \
            --system \
            --gid "$USER_GROUP" \
            --home "$USER_HOME" \
            --no-create-home \
            --comment "$USER_COMMENT" \
            --shell /bin/false \
            $USER_NAME  >/dev/null
        fi
		;;
    *)
        echo "Unsupported distribution: $DIST"
        exit 1
        ;;		
    esac
}

add_vault_user



##--------------------------------------------------------------------
## Vault 구성 파일 생성

sudo tee /etc/vault.d/vault.hcl > /dev/null <<EOF
ui = true
disable_mlock = true
storage "raft" {
  path    = "/opt/vault/data"
  node_id = "$instance_id"
  retry_join {
    auto_join = "provider=aws region=${region} tag_key=${tagname} tag_value=${tagvalue}"
%{ if certificate_body != "" &&  private_key != "" && certificate_chain != "" }       
    auto_join_scheme = "https" 
    leader_tls_servername = "${domain}"    
    leader_ca_cert_file = "/opt/vault/tls/vault-ca.pem"
    leader_client_cert_file = "/opt/vault/tls/vault-cert.pem"
    leader_client_key_file = "/opt/vault/tls/vault-key.pem"
%{ else }
    auto_join_scheme = "http" 
%{ endif }
  }
%{ if autopilot_upgrade_version != "" }
  autopilot_upgrade_version = "${autopilot_upgrade_version}"
%{ endif }
}
%{ if certificate_body != "" &&  private_key != "" && certificate_chain != "" }       
cluster_addr = "https://$local_ipv4:8201"
api_addr = "https://$local_ipv4:8200"
%{ else }
cluster_addr = "http://$local_ipv4:8201"
api_addr = "http://$local_ipv4:8200"
%{ endif }
listener "tcp" {
  address            = "0.0.0.0:8200"
%{ if certificate_body != "" &&  private_key != "" && certificate_chain != "" }       
  tls_disable        = false  
  tls_cert_file      = "/opt/vault/tls/vault-cert.pem"
  tls_key_file       = "/opt/vault/tls/vault-key.pem"
  tls_client_ca_file = "/opt/vault/tls/vault-ca.pem"
%{ else }
  tls_disable        = true  
%{ endif }
%{ if use_telemetry != "" }
  telemetry {
    unauthenticated_metrics_access = "true"
  }
%{ endif }
}

%{ if kms_key_arn != "" }
seal "awskms" {
  region     = "${region}"
  kms_key_id = "${kms_key_arn}"
} 
%{ endif }
%{ if license != "" }
license_path = "/opt/vault/vault.hclic" 
disable_performance_standby = false
disable_sealwrap = true
%{ endif }
%{ if use_telemetry != "" }
telemetry {
  disable_hostname = true    
  prometheus_retention_time = "12h"
}
%{ endif }
EOF

##--------------------------------------------------------------------
## Vault 서비스 생성
 
create_vault_service() {
    SYSTEMD_DIR=""
    DIST=$(cat /etc/os-release | grep '^ID=')
    
    case $DIST in
    'ID=ubuntu' | 'ID=debian')
        SYSTEMD_DIR="/lib/systemd/system"  
        ;;
    'ID="centos"' | 'ID="rhel"' | 'ID="amzn"')
        SYSTEMD_DIR="/etc/systemd/system"  
        ;;
    *)
        echo "Unsupported distribution: $DIST"
        exit 1
        ;;
    esac

    sudo tee $SYSTEMD_DIR/vault.service > /dev/null <<EOF
[Unit]
Description=Vault Agent

[Service]
Restart=on-failure
EnvironmentFile=/etc/vault.d/vault.hcl
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap 'cap_ipc_lock=+ep' /usr/local/bin/vault
ExecStart=/usr/local/bin/vault server -config /etc/vault.d $FLAGS
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=vault
Group=vault
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF
    sudo chmod 0664 $SYSTEMD_DIR/vault.service
}

create_vault_service

##--------------------------------------------------------------------
## Vault 환경변수 Profile 생성 및 적용

create_vault_profile_script() {
    sudo tee /etc/profile.d/vault.sh > /dev/null <<"EOF"
%{ if certificate_body != "" &&  private_key != "" && certificate_chain != "" }
export VAULT_ADDR="https://localhost:8200"
export VAULT_SKIP_VERIFY=true
%{ else }
export VAULT_ADDR="http://localhost:8200"
%{ endif }
EOF
}
create_vault_profile_script
source /etc/profile.d/vault.sh


##--------------------------------------------------------------------
## 퍼미션 설정

set_permissions() {
    sudo chown root:root /etc/vault.d
    sudo chown root:vault /etc/vault.d/vault.hcl
    sudo chmod 640 /etc/vault.d/vault.hcl
    sudo chown root:vault /opt/vault/data
    sudo chmod 777 /opt/vault/data
    sudo chown root:vault /opt/vault/logs
    sudo chmod 777 /opt/vault/logs
%{ if certificate_body != "" &&  private_key != "" && certificate_chain != "" }
    sudo chown root:root /opt/vault/tls/vault-cert.pem /opt/vault/tls/vault-ca.pem
    sudo chown root:vault /opt/vault/tls/vault-key.pem
    sudo chmod 0644 /opt/vault/tls/vault-cert.pem /opt/vault/tls/vault-ca.pem
    sudo chmod 0640 /opt/vault/tls/vault-key.pem
%{ endif }
%{ if license != "" }
    sudo chown root:vault /opt/vault/vault.hclic
    sudo chmod 0640 /opt/vault/vault.hclic
%{ endif }
}

set_permissions

##--------------------------------------------------------------------
## Vault 설치 스크립트 생성

sudo tee /tmp/install.sh > /dev/null <<EOF
install_unzip() {
  local unzipath=\$1

  if ! command -v unzip >/dev/null 2>&1; then
    echo "Unzip is not installed" 
  else
    echo "Unzip is already installed"
    return
  fi

  if [ -z "\$unzipath" ]; then
    echo "unzip path not provided"
    return
  fi

  DIST=$(cat /etc/os-release | grep '^ID=')
  case \$DIST in
    'ID=ubuntu' | 'ID=debian')
        sudo dpkg -i \$unzipath
        ;;
    'ID="centos"' | 'ID="rhel"' | 'ID="amzn"')
        sudo yum install \$unzipath
        ;;             
    *)
        echo "Unsupported distribution: \$DIST"
        exit 1
        ;;
  esac  
}

install_aws_cli() { 
    local awspath=\$1

    if ! command -v aws >/dev/null 2>&1; then
        echo "AWS CLI is not installed" 
    else
        echo "AWS CLI is already installed"
        return
    fi

    if [ -z "\$awspath" ]; then
        echo "aws installer path not provided"
        return
    fi

    unzip -o "\$awspath" -d /tmp
    if [ -e "/tmp/aws/install" ]; then
        sudo /tmp/aws/install
    else
        echo "Error: AWS CLI installation failed."
        exit 1
    fi
}

install_vault() {
    local vaultpath=\$1

    if ! command -v vault >/dev/null 2>&1; then
        echo "Vault is not installed" 
    else
        echo "Vault is already installed"
        return
    fi

    if [ -z "\$vaultpath" ]; then
        echo "vault binary path not provided"
        return
    fi

    unzip -o "\$vaultpath" -d /tmp
    if [ -e "/tmp/vault" ]; then
        sudo mv /tmp/vault /usr/local/bin/
	      sudo chmod 0755 /usr/local/bin/vault
	      sudo chown vault:vault /usr/local/bin/vault
	      sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
	      sudo mkdir -pm 0755 /etc/vault.d    
    else
        echo "Error: Vault installation failed."
        exit 1
    fi
}
while getopts a:v:z: flag
do
    case "\$flag" in
        a) awspath=\$OPTARG;;
        v) vaultpath=\$OPTARG;; 
        z) unzipath=\$OPTARG;; 
    esac
done

install_unzip "\$unzipath"
install_aws_cli "\$awspath"
install_vault "\$vaultpath"
sudo systemctl enable vault
sudo systemctl start vault
EOF

sudo chmod +x /tmp/install.sh

##----------------------------------------------
# Test Script

sudo tee /tmp/download.sh > /dev/null <<EOF
%{ if license != "" } 
  VAULT_PATH='https://releases.hashicorp.com/vault/1.12.1+ent/vault_1.12.1+ent_linux_amd64.zip'
%{ else }
  VAULT_PATH='https://releases.hashicorp.com/vault/1.12.1/vault_1.12.1_linux_amd64.zip'
%{ endif }
  AWS_PATH='https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip'
  UNZIP_PATH='http://archive.ubuntu.com/ubuntu/pool/main/u/unzip/unzip_6.0-25ubuntu1_amd64.deb'

  curl -o "/tmp/vault.zip" -L "\$VAULT_PATH"
  curl -o "/tmp/awscliv2.zip" -L "\$AWS_PATH"
  curl -o "/tmp/unzip.deb" -L  "\$UNZIP_PATH"

  /tmp/install.sh -a "/tmp/awscliv2.zip" -v "/tmp/vault.zip" -z "/tmp/unzip.deb"
EOF

sudo chmod +x /tmp/download.sh

##--------------------------------------------------------------------
# 시나리오 테스트 방법
# 1. vault.zip, awscliv2.zip, unzip.deb 파일을 scp 로 /tmp 폴더로 복사해야 함. 임시로 /tmp/download.sh 을 실행하여 임시로 파일을 다운받아 테스트를 진행할 수 있음
# 2. /tmp/install.sh -a "/tmp/awscliv2.zip" -v "/tmp/vault.zip" -z "/tmp/unzip.deb" 명령을 실행하여 각각의 서버에 vault 설치
# 3. 서버중 한곳에서 source /etc/profile.d/vault.sh
# 4. vault operator init > init.txt
# 5. vault login
# 6. vault operator raft list-peers