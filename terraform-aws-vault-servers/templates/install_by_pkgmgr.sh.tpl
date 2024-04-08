#!/usr/bin/env bash
 

imds_token=$( curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 30" -XPUT 169.254.169.254/latest/api/token )
instance_id=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/instance-id )
local_ipv4=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/local-ipv4 )

sudo timedatectl set-timezone UTC

##--------------------------------------------------------------------
## TLS Certificate 와 License 파일 저장 > 실제 이 작업은 Image 구울때 들어가야 함, 여기에서는 편의를 위해 제공
sudo mkdir -p /opt/vault/
sudo mkdir -p /opt/vault/tls
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
# Vault 설치
install_vault() {
%{ if license != "" } 
    SOLUTION="vault-enterprise"
%{ else }
    SOLUTION="vault"
%{ endif }
    
    DIST=$(cat /etc/os-release | grep '^ID=')
    
    case $DIST in
    'ID=ubuntu' | 'ID=debian')
        sudo apt update && sudo apt install -y gpg
        sudo wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install -y $SOLUTION
        ;;
    'ID="centos"' | 'ID="rhel"')
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
        sudo yum -y install $SOLUTION
        ;;
    'ID="amzn"')
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
        sudo yum -y install $SOLUTION
        ;;
    'ID=fedora')
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
        sudo dnf -y install $SOLUTION
        ;;
    *)
        echo "Unsupported distribution: $DIST"
        exit 1
        ;;		        
    esac
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
## Start vault
sudo systemctl enable vault
sudo systemctl start vault

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