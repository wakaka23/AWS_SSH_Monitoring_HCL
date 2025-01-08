#!/bin/bash

# Install Amazon SSM Agent
cd /tmp
sudo dnf --disablerepo="*" install -y https://s3.ap-northeast-1.amazonaws.com/amazon-ssm-ap-northeast-1/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Install Amazon CloudWatch Agent
sudo dnf --disablerepo="*" install -y https://s3.ap-northeast-1.amazonaws.com/amazoncloudwatch-agent-ap-northeast-1/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:${env_name}-cloudwatch-agent-${instance_index} -s

# Create Test User
sudo useradd testuser
echo "test-user:testpass" | sudo chpasswd

# Allow Password Authentication
sudo sed -i -re 's/^(#?)(PasswordAuthentication)(\s)no/\1\2\3yes/' /etc/ssh/sshd_config
sudo sed -i -re 's/^(#?)(PasswordAuthentication)(\s)no/\1\2\3yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf
sudo systemctl restart sshd