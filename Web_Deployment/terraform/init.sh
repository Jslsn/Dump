#!/bin/bash
sudo yum update -yum

sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

sudo yum install httpd -y

sudo echo -e "<html>\n<head>\n<Title> Yo </Title>\n</head>\n<body>\n<h1>Hi, name's Jordan</h1>\n</body>\n</html>" >> /var/www/html/index.html

sudo service httpd start

sudo systemctl start amazon-ssm-agent
