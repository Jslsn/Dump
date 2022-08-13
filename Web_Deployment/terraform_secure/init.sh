#!/bin/bash
sudo yum update -yum

sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

sudo systemctl start amazon-ssm-agent

sudo yum install docker -y

sudo systemctl enable docker.service

sudo systemctl start docker.service

sudo docker pull jslsn/web_deployment:webcontainerv4

sudo docker run --name jl_web_deployment -p 80:80 jslsn/web_deployment:webcontainerv4

