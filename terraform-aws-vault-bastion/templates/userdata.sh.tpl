#!/usr/bin/env bash

# Reference Site : https://github.com/hashicorp/learn-vault-raft/tree/main/raft-storage/aws/templates

imds_token=$( curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 30" -XPUT 169.254.169.254/latest/api/token )
instance_id=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/instance-id )
local_ipv4=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/local-ipv4 )

sudo timedatectl set-timezone UTC
 
##--------------------------------------------------------------------
## AWS CLI 설치

install_aws_cli() {
    DIST=$(cat /etc/os-release | grep '^ID=')
    
    case $DIST in
    'ID=ubuntu' | 'ID=debian')
        sudo apt-get -qq -y update
        sudo apt-get install -qq -y awscli
        ;;
    'ID="centos"' | 'ID="rhel"')
        curl --silent -O https://bootstrap.pypa.io/pip/2.7/get-pip.py 
        sudo python get-pip.py
        sudo pip install awscli
        ;;
    'ID="amzn"')
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        ;;
    'ID=fedora')
        sudo dnf install -y epel-release
        sudo dnf install -y awscli
        ;;
    esac
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
  SOLUTION="vault"
	VAULT_ZIP='https://releases.hashicorp.com/vault/1.13.1/vault_1.13.1_linux_amd64.zip'

	curl -o /tmp/vault.zip $${VAULT_ZIP}
	sudo unzip -o /tmp/vault.zip -d /usr/local/bin/
	sudo chmod 0755 /usr/local/bin/vault
	sudo chown vault:vault /usr/local/bin/vault
	sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
	sudo mkdir -pm 0755 /etc/vault.d
}

install_vault