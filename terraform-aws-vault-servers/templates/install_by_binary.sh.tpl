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

%{ if certificate_body != "" &&  private_key != "" && certificate_chain != "" }
echo "${certificate_body}" | sudo tee /opt/vault/tls/vault-cert.pem > /dev/null
echo "${private_key}" | sudo tee /opt/vault/tls/vault-key.pem  > /dev/null
echo "${certificate_chain}" | sudo tee /opt/vault/tls/vault-ca.pem > /dev/null
%{ endif }

%{ if license != "" }
echo "${license}" | sudo tee /opt/vault/vault.hclic > /dev/null
%{ endif }


##--------------------------------------------------------------------
## AWS CLI 설치

install_aws_cli() {
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
}

install_aws_cli

##--------------------------------------------------------------------
## Vault 설치 관련 필요 패키지 추가

add_vault_requisite() { 
    DIST=$(cat /etc/os-release | grep '^ID=')
    
    case $DIST in
    'ID=ubuntu' | 'ID=debian')
        sudo apt-get -qq -y update
        sudo apt-get install -qq -y wget unzip dnsutils ruby rubygems ntp jq
        sudo systemctl start ntp.service
        sudo systemctl enable ntp.service
        sudo sh -c 'echo "\nUseDNS no" >> /etc/ssh/sshd_config'
        sudo service ssh restart	
        ;;
    'ID="centos"' | 'ID="rhel"' | 'ID="amzn"')
        sudo yum-config-manager --enable rhui-REGION-rhel-server-releases-optional
        sudo yum-config-manager --enable rhui-REGION-rhel-server-supplementary
        sudo yum-config-manager --enable rhui-REGION-rhel-server-extras
        sudo yum -y check-update
        sudo yum install -q -y wget unzip bind-utils ruby rubygems ntp jq
        sudo systemctl start ntpd.service
        sudo systemctl enable ntpd.service	
		;;
    *)
        echo "Unsupported distribution: $DIST"
        exit 1
        ;;		
    esac
}

add_vault_requisite

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
# Vault 설치

install_vault() {
%{ if license != "" } 
	VAULT_ZIP='https://releases.hashicorp.com/vault/${version}+ent/vault_${version}+ent_linux_amd64.zip'
%{ else }
	VAULT_ZIP='https://releases.hashicorp.com/vault/${version}/vault_${version}_linux_amd64.zip'
%{ endif }

	curl -o /tmp/vault.zip $${VAULT_ZIP}
	sudo unzip -o /tmp/vault.zip -d /usr/local/bin/
	sudo chmod 0755 /usr/local/bin/vault
	sudo chown vault:vault /usr/local/bin/vault
	sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
	sudo mkdir -pm 0755 /etc/vault.d
}

install_vault


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
## Vault 파일 및 디렉토리 퍼미션 설정

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
## Vault 서비스 실행

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

sudo systemctl enable vault
sudo systemctl start vault 
create_vault_profile_script
source /etc/profile.d/vault.sh
echo 'complete -C /usr/local/bin/vault vault' >> ~/.bashrc
source ~/.bashrc