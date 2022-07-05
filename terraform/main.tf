terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_template" "template" {
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}

locals {
  instance_count = 3
}

resource "aws_autoscaling_group" "instances" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = local.instance_count
  min_size           = 1

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  warm_pool {
    instance_reuse_policy {
      reuse_on_scale_in = true
    }
  }
}

data "aws_instances" "group_instances" {
  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.instances.name
  }

  instance_state_names = ["running", "stopped"]
}


output "instance_ids" {
  value = data.aws_instances.group_instances.ids
}
