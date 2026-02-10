#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt-get update -y
apt-get upgrade -y
apt-get install -y apache2

a2dismod autoindex || true
a2dismod status || true
a2dismod userdir || true
a2dismod info || true

systemctl restart apache2

apt-get install -y ruby-full wget

cd /tmp
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto

systemctl start codedeploy-agent
systemctl enable codedeploy-agent