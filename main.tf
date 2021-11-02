provider "aws" {
  region = "us-east-2"
}

variable "server_port" {
  description = "Port utilisé pour le serveur WEB"
  type        = number
  default     = 8080

}



resource "aws_launch_configuration" "exemple" {
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  user_data     = <<-EOF
  #!/bin/bash
  echo "Hello, World" > index.html
  nohup busybox httpd -f -p ${var.server_port} &
  EOF
  # vpc_security_group_ids = [aws_security_group.instance.ids]
  lifecycle {
    create_before_destroy = true
  }

}
resource "aws_autoscaling_group" "exemple" {
  launch_configuration = aws_launch_configuration.exemple.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10
  tag  {
    key                 = "name"
    value               = "terraform-asg-exemple"
    # Name                = "terraform-example"
    propagate_at_launch = true
  }

}
resource "aws_security_group" "instance" {
  name = "terraform-exemple-instance"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "value"
    from_port   = var.server_port
    # ipv6_cidr_blocks = [ "::/0" ]
    # prefix_list_ids = ["anything"]
    protocol = "tcp"
    # security_groups = [ "value" ]
    # self = false
    to_port = var.server_port
  }

}
data "aws_vpc" "default" {
  default = true /* in order to find the default VPC */

}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_lb" "exemple" {
  name               = "terraform-ald-exemple"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.alb.id]

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.exemple.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404:page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-exemple-alb"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}


output "alb_dns_name" {
  description = "The domain name of the load balancer"
  value       = aws_lb.exemple.dns_name

}