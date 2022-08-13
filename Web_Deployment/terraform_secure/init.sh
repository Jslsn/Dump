#!/bin/bash
public_image=jslsn/web_deployment:webcontainerv4

sudo yum update -yum

sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

sudo systemctl start amazon-ssm-agent

sudo yum install docker -y

sudo systemctl enable docker.service

sudo systemctl start docker.service

sudo docker pull ${public_image}

sudo docker run --name jl_web_deployment -p 80:80 ${public_image}

