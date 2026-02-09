terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.2"
  
  backend "s3" {
    bucket = "bucket-terraform-github-actions"
    key    = "terraform/state.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "deploy" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.deploy_instance_type
  vpc_security_group_ids = [aws_security_group.deploy.id]
  key_name               = var.key_name
  tags = {
    Name = var.deploy_name
  }
  user_data                   = file("scripts/apache.sh")
  user_data_replace_on_change = true
  iam_instance_profile        = aws_iam_instance_profile.deploy_profile.name
}

resource "aws_security_group" "deploy" {
  name        = var.security_name_deploy
  description = "SSH and HTTP"
  tags = {
    Name = var.security_name_deploy
  }
}

resource "aws_vpc_security_group_ingress_rule" "deploy_allow_ssh" {
  security_group_id = aws_security_group.deploy.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "deploy_allow_http_ipv4" {
  security_group_id = aws_security_group.deploy.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_deploy" {
  security_group_id = aws_security_group.deploy.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_iam_instance_profile" "deploy_profile" {
  name = "ec2-codedeploy-profile"
  role = data.aws_iam_role.lab_role.name
}

resource "aws_codedeploy_app" "app" {
  name = "codedeploy-app"
}

resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "codedeploy-deployment-group"
  service_role_arn      = data.aws_iam_role.lab_role.arn

  ec2_tag_filter {
    type  = "KEY_AND_VALUE"
    key   = "Name"
    value = var.deploy_name
  }
}
