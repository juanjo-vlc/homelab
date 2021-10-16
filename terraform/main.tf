terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63"
    }
  }

  required_version = ">= 1.0.9"
}

provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_launch_template" "terra1" {
  name_prefix            = var.name_prefix
  image_id               = var.image_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_groups
  user_data              = var.init_script
  tags = {
        Department = "terraform"
        Name = "terra1_autoscaling"
  }
}

resource "aws_autoscaling_group" "terra1" {
  availability_zones = var.availability_zones
  desired_capacity   = var.autoscaling_capacity
  max_size           = var.autoscaling_max_size
  min_size           = var.autoscaling_min_size

  launch_template {
    id      = aws_launch_template.terra1.id
    version = "$Latest"
  }

  load_balancers = [aws_elb.terra1.name]
}

resource "aws_elb" "terra1" {
  security_groups    = var.security_groups
  availability_zones = var.availability_zones
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:80/"
  }
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "80"
    instance_protocol = "http"
  }
}
