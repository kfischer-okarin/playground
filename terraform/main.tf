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

resource "aws_instance" "instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  count = 3

  tags = {
    Name = "terraform-test-instance"
  }
}


resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  inline_policy {
    name = "lambda-policy"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "ec2:DescribeInstances",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
  }
}


resource "aws_lambda_function" "test_lambda" {
  # zip handler.zip handler.py
  filename      = "handler.zip"
  function_name = "test_lambda"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "handler.handler"

  source_code_hash = filebase64sha256("handler.zip")

  runtime = "python3.9"

  environment {
    variables = {
      INSTANCE_NAME = aws_instance.instance[0].tags.Name
    }
  }
}
